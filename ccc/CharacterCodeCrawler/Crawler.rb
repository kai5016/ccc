require 'rubygems'
require 'anemone'

class Crawler
  Anemone.crawl("http://www.example.com/") do |anemone|
    anemone.on_every_page do |page|
      # 現在見ているページの URL を取得
       page.url
      # タイトルの取得
      title = page.doc.xpath("//head/title/text()").first.to_s if page.doc
      puts title
      # リンクの URL のリストを取得
      page.links().each {|link|
        puts "link," + url.to_s + "," + link.to_s
      }
    end
  end
end