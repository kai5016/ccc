require 'rubygems'
require 'anemone'

class Crawler
  Anemone.crawl("http://www.example.com/") do |anemone|
    anemone.on_every_page do |page|
      # 現在見ているページの URL を取得
      puts page.url
      # タイトルの取得
      title = page.doc.xpath("//head/title/text()").first.to_s if page.doc
      puts title
    end
  end
end