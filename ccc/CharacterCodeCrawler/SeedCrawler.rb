# -*- encoding: utf-8 -*-

require 'rubygems'
require 'logger'
require 'nokogiri'
require 'open-uri'
require 'openssl'
require '.\PageScraper'
require '..\Dao\FetchUrlDao'
require '..\Dao\ScrapeResultDao'

class SeedCrawler
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  LAST_PAGE = 990

  log = Logger.new("crawler.log")
  log.progname = $PROGRAM_NAME
  log.level = Logger::INFO

  scrape_result_dao = ScrapeResultDao.new
  fetch_url_dao = FetchUrlDao.new
  scraper = PageScraper.new

  # データの用意
  seed_url = "https://www.google.co.jp/search?q=blog&lr=lang_vi&hl=ja&as_qdr=all&ie=UTF-8&tbs=lr:lang_1vi&prmd=ivnsl&ei=VihuUp3gBMW_kQXZrYCgDA&sa=N#as_qdr=all&filter=0&hl=ja&lr=lang_vi&q=blog&safe=off&tbs=lr:lang_1vi&start="

  # 0から10刻みで990まで，pagenum を増加させて URL を生成
  # 生成した URL に対してクロールを実行
  (0..LAST_PAGE).step(10) do |pagenum|
    url = seed_url + pagenum.to_s
    log.info "SEED URL[#{url} をクロールします．"
    
    # ドキュメントの取得
    doc = nil
    begin
      timeout(10) do
        doc = Nokogiri::HTML(open(url))
      end
    rescue Timeout::Error
      puts "Time out connection request"
      raise
    end
    
    # リンク先の抽出
    link_urls = Array.new
    doc.xpath("//h3/a").each { |node|
      href = node["href"]
      href.gsub!(/\/url\?q=/, "")
      if href.start_with?("http")
        log.info "href[#{href}]"
        link_urls.push(href)
      else
        log.info "href[#{href}] は処理対象ではありません"
      end
    }
    log.info "#{link_urls.size} 件の URL を抽出しました"

    fetch_url_dao.skip_or_insert(link_urls, FetchUrlListDao::SEED)
  end
end