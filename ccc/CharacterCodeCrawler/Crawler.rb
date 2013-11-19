# -*- encoding: utf-8 -*-

require 'rubygems'
require 'logger'
require 'anemone'

require '.\PageScraper'
require '..\Dao\FetchUrlListDao'
require '..\Dao\ScrapeResultDao'

#-- anemone クローラー実行クラス
class Crawler
  log = Logger.new("crawler.log")
  log.progname = $PROGRAM_NAME
  log.level = Logger::INFO  
  opts = {
    :skip_query_strings => true,
#    :depth_limit => 1,
  }

  # クロール  実行部分
  begin      
    current_url = fetch_url_list_dao.get_waiting_url
    puts "URL[#{current_url}] をクロールします．"
    Anemone.crawl(current_url) do |anemone|
      anemone.storage = Anemone::Storage.MongoDB
      anemone.on_every_page do |page|
        if fetch_url_list_dao.skip?(page.url.to_s) then
          next
        end
        page_info = scraper.scrape(page)
        scrape_result_dao.insert_or_update(page_info)
        fetch_url_list_dao.skip_or_insert(page.links())
        fetch_url_list_dao.update_status(page_info.url, FetchUrlListDao::DONE)
      end
      # このタイミングで current_url は status = 2 (処理終了) でなければおかしい
      # もう一度 処理待ちの URLを取得した際に，取得した URL と current_url を比較し，
      # 処理が無事終了しているかを判断する．
      # 比較の結果等しければ，status = 3 (異常終了) に更新する
      if current_url == fetch_url_list_dao.get_waiting_url
        fetch_url_list_dao.update_status(current_url, FetchUrlListDao::ERROR)
      end
    end
  end while fetch_url_list_dao.exist_waiting_url?

end