require 'C:\AptanaStudio3\workspace\ccc\CharacterCodeCrawler\PageInfo'

class PageScraper
  def scrape(page)
    page_info = PageInfo.new()
    # 現在見ているページの URL を取得
    url = page.url
    puts url
    page_info.url = url
    # タイトルの取得
    title = page.doc.xpath("//title/text()").first.to_s if page.doc
    puts "title\t#{title}"
    page_info.title = title
    # 文字コードの取得
    char_code = page.doc.xpath("//meta[contains(@content,'charset')]").attribute("content") if page.doc
    puts char_code
    page_info.char_code = char_code
    # リンクの URL のリストを取得
    link_list = page.links()
    link_list.each {|link|
      puts "link," + link.to_s
    }
  end
end