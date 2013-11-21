# -*- encoding: utf-8 -*-

require 'nokogiri'
require '..\Dao\ScrapeResultDao'
require '..\Dao\CharCountDao'
require '..\eprun\lib\string_normalize'

class CrawlDataParser
  # ベトナム語の1文字辺りの出現数をカウントする
  def count_character_indb(dao)
    scrape_result_dao = ScrapeResultDao.new
    docs = scrape_result_dao.get_all_documents
    docs.add_option(Mongo::Constants::OP_QUERY_NO_CURSOR_TIMEOUT)
    docs.each { |doc|
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
        next
      end
      puts
    }
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

end

log = Logger.new("parser.log")
log.progname = $PROGRAM_NAME
log.level = Logger::DEBUG

dao = ScrapeResultDao.new
docs = dao.find_by_normalized_flg(false)
docs.each{ |doc|
  body = doc["body"]
  log.info "URL: #{doc["url"]}"
  log.info "normalized_flg: #{body.normalize_check}"
  log.info Normalize::NF_HASH_C
  Normalize::NF_HASH_C.clear
}
