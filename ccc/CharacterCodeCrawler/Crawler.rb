# -*- encoding: utf-8 -*-

require 'rubygems'
require 'logger'
require 'anemone'
require '.\PageScraper'
require '..\Dao\FetchUrlDao'
require '..\Dao\ScrapeResultDao'

#-- anemone の機能拡張

#-- 抽出したリンク URL が外部ドメインかどうか判断しない
class Anemone::Page
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

#-- anemone クローラー実行クラス
class Crawler
  log = Logger.new("crawler.log")
  log.progname = $PROGRAM_NAME
  log.level = Logger::DEBUG
  
  # anemone に渡すオプション
  opts = {
    :skip_query_strings => true,
    :depth_limit => 1,
  }

  fetch_url_dao = FetchUrlDao.new(log)
  scrape_result_dao = ScrapeResultDao.new(log)
  scraper = PageScraper.new(log)

  # クロール  実行部分
  begin
    current_url = fetch_url_dao.get_waiting_url
    log.info "URL[#{current_url}] をクロールします．"
    Anemone.crawl(current_url, opts) do |anemone|
      anemone.storage = Anemone::Storage.MongoDB
      anemone.on_every_page do |page|
        if fetch_url_dao.skip?(page.url.to_s) then
          next
        end
        page_info = scraper.scrape(page)
        scrape_result_dao.insert_or_update(page_info)
        fetch_url_dao.skip_or_insert(page.all_links, FetchUrl::OTHER, page.depth + 1)
        fetch_url_dao.update_status(page_info.url, page.code)
      end
      # このタイミングで current_url は status = 2 (処理終了) でなければおかしい
      # もう一度 処理待ちの URLを取得した際に，取得した URL と current_url を比較し，
      # 処理が無事終了しているかを判断する．
      # 比較の結果等しければ，status = 3 (異常終了) に更新する
#      if current_url == fetch_url_list_dao.get_waiting_url
#        fetch_url_dao.update_status(current_url, FetchUrlListDao::ERROR)
#      end
    end
  end while fetch_url_dao.exist_waiting_url?

end