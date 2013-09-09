require 'rubygems'
require 'anemone'

require 'C:\AptanaStudio3\workspace\ccc\CharacterCodeCrawler\PageScraper'

class Crawler
  opts = {
    :skip_query_strings => true,
    :depth_limit => 1,
  }
  scraper = PageScraper.new()
  Anemone.crawl("http://blog.livedoor.jp/news23vip/") do |anemone|
    anemone.on_every_page do |page|
      scraper.scrape(page)
    end
  end
end