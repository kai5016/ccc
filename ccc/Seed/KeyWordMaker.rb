# -*- encoding: utf-8 -*-

require '..\Dao\ScrapeResultDao'
require '..\CharacterCodeCrawler\VietChar'

#--scrape_result から body をひとつ取得して，
#--body に出現する単語を google 検索用のキーワードに変換するモジュール
module KeyWordMaker
  def KeyWordMaker.make_key_words
    dao = ScrapeResultDao.new
    doc = dao.get_document
    body = doc["body"]
    chars = body.split(" ")
    chars.uniq!
    viet_chars = []
    chars.each {|c|
      new_c = c.gsub(/[!-\/:-@\[-`{-~]/, "")
      next if c == "–"
      new_c = new_c.gsub(/[0-9A-Za-z]/, "")
      if new_c != ""
        viet_chars << new_c
      end
    }
    
    puts viet_chars
    puts "#{viet_chars.size} key_words were found."

    viet_chars.each{|c|
      VietChar::VIET_CHAR_IN_GOOGLE.each_key {|key|
        c.gsub!(key, VietChar::VIET_CHAR_IN_GOOGLE[key])
      }
    }

    viet_chars
  end
end