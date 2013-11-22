# -*- encoding: utf-8 -*-

require 'nokogiri'
require '..\Dao\ScrapeResultDao'
require '..\Dao\CharCountDao'
require '..\eprun\lib\string_normalize'

class CrawlDataParser
  def initialize(log = nil)
      @log = log || Logger.new("parser.log")
    end
    attr_reader :log
  # ベトナム語の1文字辺りの出現数をカウントする
  def count_character_indb(dao)
    scrape_result_dao = ScrapeResultDao.new
    docs = scrape_result_dao.get_all_documents
    docs.add_option(Mongo::Constants::OP_QUERY_NO_CURSOR_TIMEOUT)
    docs.each { |doc|
      count_byte(doc)
    }
  end

  # 取得したドキュメントの文字列の byte をカウントする
  def count_byte(doc)
    begin
      body = doc["body"]
      body.each_char { |c|
        if c.bytesize > 1 then
          byte = "0x"
          c.bytes { |b| byte = byte + b.to_s(16)}
          print "#{c}[#{byte}]"
          dao.insert_or_count_up(c, byte)
        end
      }
    rescue => ex
      puts ex.message
    end
    puts
  end

  # 抽出された文字列が正規化されているかチェックを行う
  def check_normalize(dao)
    docs = dao.get_all_documents
    docs.add_option(Mongo::Constants::OP_QUERY_NO_CURSOR_TIMEOUT)
    docs.each { |doc|
      body = doc["body"]
      dao.set_normalized_flg(body.normalize_check, doc["url"])
    }
  end

  # ドキュメントの body から正規化される文字のハッシュマップを返す
  def get_normalize_hash(doc)
    Normalize::NF_HASH_C.clear
    body = doc["body"]
    log.info "URL: #{doc["url"]}"
    log.info "normalized_flg: #{body.normalize}"
    hash = Normalize::NF_HASH_C
    log.info hash
    return hash
  end
  
  # 文字列中に正規化が必要な文字がいくつあるかカウントをする
  def count_none_normalized(str)
    count = Hash.new(0)
    matches = str.scan(Normalize::REGEXP_C)
    matches.each { |match|
      count[match] += 1
    }
    return count
  end

end

scrape_result_dao = ScrapeResultDao.new
parser = CrawlDataParser.new
doc = scrape_result_dao.find_one_by_normalized_flg(false)
body = doc["body"]
count = parser.count_none_normalized(body)

puts doc["url"]
puts count
puts parser.get_normalize_hash(doc)
