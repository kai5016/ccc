require '..\Dao\ScrapeResultDao'
require '..\CharacterCodeCrawler\VietChar'

module KeyWordMaker
  def make_key_words
    dao = ScrapeResultDao.new
    doc = dao.get_document
    body = doc["body"]
    chars = body.split(" ")
    chars.uniq!
    viet_chars = []
    chars.each {|c|
      new_c = c.gsub(/[!-\/:-@\[-`{-~]/, "")
      new_c = new_c.gsub(/[0-9A-Za-z]/, "")
      if new_c != ""
        viet_chars << new_c
      end
    }

    viet_chars.each{|c|
      VietChar::VIET_CHAR_IN_GOOGLE.each_key {|key|
        c.gsub!(key, VietChar::VIET_CHAR_IN_GOOGLE[key])
      }
    }

    viet_chars
  end
end