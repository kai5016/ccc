# -*- encoding: utf-8 -*-

require 'mongo'

#= 文字の出現回数を管理するためのコレクション char_cout
#  にアクセスするためのクラス
class CharCountDao
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log
  
  DB_NAME = "character_code_crawler"
  COLLECTION_NAME = "char_count"

  # DB に接続し ，コレクション "char_count" オブジェクトを生成する
  def get_collection()
    connection = Mongo::Connection.new
    db = connection.db(DB_NAME)
    coll = db.collection(COLLECTION_NAME)
  end

  # 既に登録済みの URL はスキップし，未登録の URL のみインサート．
  def insert_or_count_up(char, byte)
    coll = get_collection()
    count = get_count(coll, byte)
    if count > 0 then
      log.debug "byte[#{byte}] をカウントアップ．"
      update_count(coll, count+1, byte)
    else
      insert(coll, char, byte)
      log.debug "[#{char}:#{byte}] をインサートしました．"
    end
  end

  # char_count に byte を登録する
  def insert(coll, char, byte)
    log.info "#{COLLECTION_NAME} に 文字[#{char}][#{byte}] をインサートします．"
    doc = {
      'char' => char,
      'byte' => byte,
      'count' => 1,
      'create_ts' => Time.now,
      'update_ts' => Time.now}
    coll.insert(doc)
    log.debug "インサート完了"
  end

  # 既に byte が登録されている場合はカウントアップする
  def update_count(coll, count, byte)
    coll.update({"byte" => byte}, {"$set" => {"count" => count}})
    log.debug "byte[#{byte}] のカウントを #{count} に更新しました．"
  end

  # 引数の URL がコレクション内に存在しているか
  def get_count(coll, byte)
    doc = coll.find_one("byte" => byte)
    if doc.to_s == "" then
      log.info "byte[#{byte}] は #{COLLECTION_NAME} 内に存在しません．"
      return 0
    end
    log.info "byte[#{byte}] は #{COLLECTION_NAME} 内に既に存在します．"
    return doc["count"]
  end

end