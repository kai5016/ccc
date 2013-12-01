# -*- encoding: utf-8 -*-

require 'logger'
require '.\PageInfo'

#= Web ページのソースから、必要項目の抽出をおこなう
#
# 抽出結果は PageInfo のインスタンスに格納し，それを返す
#
#== 必要項目
#- タイトル
#- 文字コード
#- 本文
class PageScraper
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log

  # 必要項目の抽出を行う
  def scrape(page)
    page_info = PageInfo.new
    url = page.url.to_s
    log.info "URL[#{url}] のスクレイプ開始"

    page_info.url = url
    page_info.charset = page.content_type.to_s
    log.debug "Content type\t [#{page_info.charset}]"

    doc = page.doc
    if doc != nil
      page_info.title = scrape_title(doc)
      log.debug "Title\t [#{page_info.title}]"
      
      page_info.act_charset = scrape_charset(doc)
      log.debug "Scraped content type\t [#{page_info.act_charset}]"
      
      page_info.body = doc.to_s
    else
      page_info.act_charset = ""
      page_info.body = "Failed to extract a body."
      log.ERROR "#{url} の body は抽出できませんでした．"
    end
    # tag 除去がうまく走らない場合があるのでそれが改善されるまで，body をそのまま格納
    #    page_info.body = extract_text(page.doc)
    #    log.debug "body\t [#{page_info.body}]"

    return page_info
  end

  # Web ページソースからタイトルを抽出
  def scrape_title(doc)
    doc.xpath("//title/text()").first.to_s
  end

  def scrape_charset(doc)
    doc.xpath("//meta").each { |node|
      charset = node["content"]
      return charset if charset.include?("charset")
    }
    return ""
  end

  # 再帰的に HTML ソースから tag の除去を行う
  def extract_text(e)
    if e.is_a? Nokogiri::XML::Text
      return e.text
    end

    e.children.inject(String.new) { |text, child|
      text << extract_text(child)
      text
    }
  end

end
