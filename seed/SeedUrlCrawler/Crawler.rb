# -*- encoding: utf-8 -*-

require 'rubygems'
require 'anemone'
require '.\PageScraper'
require '.\FetchUrlListDao'

#-- CharacterCodeCrawler 用の Seed URL を収集するクローラ
class Crawler
  opts = {
    :skip_query_strings => true,
    #    :depth_limit => 1,
  }

  scrape_result_dao = ScrapeResultDao.new()
  fetch_url_list_dao = FetchUrlListDao.new()
  scraper = PageScraper.new()

  seed_urls = Array.new
  fetch_url_list_dao.skip_or_insert(seed_urls)

  # クロール  実行部分
  Anemone.crawl("") do |anemone|
    anemone.storage = Anemone::Storage.MongoDB
    anemone.on_every_page do |page|
      if fetch_url_list_dao.skip?(page.url.to_s) then
        next
      end
      page_info = scraper.scrape(page)
      fetch_url_list_dao.skip_or_insert(page.links())
    end
  end
end