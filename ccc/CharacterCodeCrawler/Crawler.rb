# -*- encoding: utf-8 -*-

require 'rubygems'
require 'logger'
require 'anemone'
require '.\PageScraper'
require '.\VietChar'
require '..\Dao\FetchUrlDao'
require '..\Dao\ScrapeResultDao'

#-- anemone の機能拡張
module Anemone
  def Anemone.crawl_db(fetch_urls_dao, options = {}, &block)
    Core.crawl_db(fetch_urls_dao, options, &block)
  end
end

class Anemone::Page
  # 外部サイトのリンクも抽出する
  def all_links
    return @links unless @links.nil?
    @links = []
    return @links if !doc

    doc.css('a').each do |a|
      u = a.attributes['href'].content rescue nil
      next if u.nil? or u.empty?
      abs = to_absolute(URI(u)) rescue next
      @links << abs
    end
    @links.uniq!
    @links
  end
end
  
class Anemone::Core
  def initialize(fetch_urls_dao, opts = {})
    @tentacles = []
    @on_every_page_blocks = []
    @on_pages_like_blocks = Hash.new { |hash,key| hash[key] = [] }
    @skip_link_patterns = []
    @after_crawl_blocks = []
    @opts = opts
    @fetch_urls_dao = fetch_urls_dao

    yield self if block_given?
  end

  def self.crawl_db(fetch_urls_dao, opts = {})
    self.new(fetch_urls_dao, opts) do |core|
      yield core if block_given?
      core.run_db
    end
  end

  #-- DB に Queue の振る舞いをさせてクロールを実行する
  def run_db
    process_options

    link_queue = @fetch_urls_dao
    page_queue = Queue.new

    Anemone::Tentacle.new(link_queue, page_queue, @opts).run_db
    page = page_queue.deq
    @pages.touch_key page.url
    puts "#{page.url} Queue: #{link_queue.num_waiting}" if @opts[:verbose]
    do_page_blocks page
    page.discard_doc! if @opts[:discard_page_bodies]
    self
  end
end

class Anemone::Tentacle
  def run_db
      link, depth = @link_queue.deq

      @http.fetch_pages(link).each { |page| @page_queue << page }
      delay
  end
end

#-- anemone クローラー実行クラス
class Crawler
  log = Logger.new("crawler.log")
  log.progname = $PROGRAM_NAME
  log.level = Logger::DEBUG
  
  # anemone に渡すオプション
  opts = {
    :skip_query_strings => true,
    :depth_limit => 1,
    :obey_robots_txt => true
  }

  fetch_url_dao = FetchUrlDao.new(log)
  scrape_result_dao = ScrapeResultDao.new(log)
  scraper = PageScraper.new(log)

  # クロール  実行部分
  begin
    Anemone.crawl_db(fetch_url_dao, opts) do |anemone|
      anemone.storage = Anemone::Storage.MongoDB
      anemone.on_every_page do |page|
        begin
          current_url = page.url.to_s
          log.info "Check the contents of Page[#{current_url}] has viet char"
          if !VietChar.viet?(page.doc.to_s)
            log.info "Page[#{current_url}] Viet char was not found. [Processing is complete]"
            fetch_url_dao.update_status(current_url, FetchUrl::NONE_VIET_CHAR)
            next
          end
          log.info "Check a content_type of Page[#{current_url}] "
          if /.+?(jis|JIS|Jis).*/ === page.content_type.to_s
            log.info "Page[#{current_url}] is written shift_jis．[Processing is complete]"
            fetch_url_dao.update_status(page_info.url, FetchUrl::EncodingError)
            next
          end
          
          log.info "Starts to scrape Page[#{page.url}]"
          page_info = scraper.scrape(page)
          scrape_result_dao.insert_or_update(page_info)
          fetch_url_dao.skip_or_insert(page.all_links, FetchUrl::OTHER, page.depth + 1)
          fetch_url_dao.update_status(page_info.url, page.code)
        rescue BSON::InvalidStringEncoding => ex
          fetch_url_dao.update_status(page_info.url, FetchUrl::EncodingError)
        end
      end
      # このタイミングで current_url は status = 1 (処理待ち) ではおかしい
      # もう一度 処理待ちの URLを取得した際に，取得した URL と current_url を比較し，
      # 同じ URL が確認できたときは，１つの URL を何度もクロールしようとするので，エラーフィールドに追加する
#      if current_url == fetch_url_dao.get_waiting_url
#        fetch_url_dao.update_error(current_url)
#      end
    end
  end while fetch_url_dao.exist_waiting_url?
  
end
