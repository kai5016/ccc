# -*- encoding: utf-8 -*-

require 'nokogiri'
require '..\Dao\ScrapeResultDao'
require '..\Dao\CharCountDao'
require '..\eprun\lib\string_normalize'

class NormalizedChecker
  def initialize(log = nil)
    @log = log || Logger.new("crawlData.log")
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
    hash = Normalize::NF_HASH_C
    log.info hash
    return hash
  end

  # 文字列中に正規化が必要な文字がいくつあるかカウントをする
  def count_none_normalized(str, form = :nfc)
    count = Hash.new(0)
    mode = {:nfc => Normalize::REGEXP_C, :nfd => Normalize::REGEXP_D}
    matches = str.scan(mode[form])
    matches.each { |match|
      count[match] += 1
    }
    log.info count
    return count
  end

  # NFD で得たカウントと，NFC で得たカウントの差をとる
  def diff_nfd_nfc(nfd_hash, nfc_hash)
    diff = Hash.new(0)
    nfc_hash.each{ |key, value|
      log.debug "NFD でカウントした結果: #{nfd_hash[key]}"
      log.debug "NFC でカウントした結果: #{nfc_hash[key]}"
      diff[key] = nfd_hash[key] - value
    }
    log.info "diff: #{diff}"
    return diff
  end

end

scrape_result_dao = ScrapeResultDao.new
checker = NormalizedChecker.new
docs = scrape_result_dao.find_by_normalized_flg(false)
docs.each { |doc|
  body = doc["body"]
  checker.get_normalize_hash(doc)
  nfc_count = checker.count_none_normalized(body)
  nfd_count = checker.count_none_normalized(body, :nfd)
  checker.diff_nfd_nfc(nfd_count,nfc_count)
}
