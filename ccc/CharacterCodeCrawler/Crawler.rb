# -*- encoding: utf-8 -*-

require 'rubygems'
require 'logger'
require 'anemone'
require '.\PageScraper'
require '.\VietChar'
require '..\Dao\FetchUrlDao'
require '..\Dao\ScrapeResultDao'
require '..\Dao\InvalidDomainDao'

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
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log
  
  def crawl
    fetch_url_dao = FetchUrlDao.new(@log)
    scrape_result_dao = ScrapeResultDao.new(@log)
    invalid_domain_dao = InvalidDomainDao.new(@log)
    scraper = PageScraper.new(@log)
    
    # クロール  実行部分
    begin
      run(fetch_url_dao, scrape_result_dao, invalid_domain_dao, scraper)
    end while fetch_url_dao.exist_waiting_url?
  end
  
  def run(fetch_url_dao, scrape_result_dao, invalid_domain_dao, scraper)
    # anemone に渡すオプション
    opts = {
      :skip_query_strings => true,
      :depth_limit => 1,
      :obey_robots_txt => true
    }
    
    current_url = ""
    Anemone.crawl_db(fetch_url_dao, opts) do |anemone|
      anemone.storage = Anemone::Storage.MongoDB
      anemone.on_every_page do |page|
        begin
          current_url = page.url.to_s
          next unless crawl?(page, fetch_url_dao, invalid_domain_dao)

          page_info = scraper.scrape(page)
          scrape_result_dao.insert_or_update(page_info)
          page.all_links.each { |link|
            url = link.to_s
            unless invalid_domain_dao.exist?(url)
              fetch_url_dao.skip_or_insert(url, FetchUrl::OTHER, page.depth + 1)
            end
          }
          fetch_url_dao.update_status(page_info.url, page.code)

        rescue BSON::InvalidStringEncoding => ex
          fetch_url_dao.update_status(page_info.url, FetchUrl::EncodingError)
        rescue Encoding::CompatibilityError => ex
          log.error "[ERROR]#{ex} in URL[#{current_url}]"
          puts "[ERROR]#{ex} in URL[#{current_url}]"
          fetch_url_dao.update_status(current_url, FetchUrl::EncodingError)
          next
        rescue VietArgumentException => ex
          log.error "[ERROR]#{ex} in URL[#{current_url}]"
          puts "[ERROR]#{ex} in URL[#{current_url}]"
          fetch_url_dao.update_status(current_url, FetchUrl::EncodingError)
          next
        end
      end
    end
  end

  def crawl?(page, fetch_url_dao, invalid_domain_dao)
    url = page.url.to_s

    content_type = page.content_type
    log.info "content_type of URL[#{url}] is [#{content_type}]."
    if content_type.nil? && content_type.include?("1258")
      log.info "this content_type is Vietnamese[#{content_type}]."
      return true
    end
    
    log.info "Check the domain of URL[#{url}] is valid"
    if invalid_domain_dao.exist?(url)
      fetch_url_dao.update_status(url, FetchUrl::INVALID_DOMAIN)
      return false      
    end
    http_code = 999
    http_code = page.code if !page.code.nil?
    log.info "Page[#{url}]'s HTTP status code is [#{http_code}]"
    if http_code >= 300
      fetch_url_dao.update_status(url, http_code)
      return false
    end

    log.info "Check the content_type of this page[#{url}]"
    if /.+?(jis|JIS|Jis).*/ === page.content_type.to_s
      log.info "Page[#{url}] is written in shift_jis．[Processing is complete]"
      fetch_url_dao.update_status(url, FetchUrl::EncodingError)
      return false
    end

    log.info "Check the contents of Page[#{url}] has viet char"
    if !VietChar.viet?(url, page.doc.to_s)
      log.info "Page[#{url}] Viet char was not found. [Processing is complete]"
      fetch_url_dao.update_status(url, FetchUrl::NONE_VIET_CHAR)
      invalid_domain_dao.insert(url)
      return false
    end
    
    return true
  end
end

log = Logger.new("crawler.log")
log.progname = $PROGRAM_NAME
log.level = Logger::DEBUG

crawler = Crawler.new(log)
crawler.crawl