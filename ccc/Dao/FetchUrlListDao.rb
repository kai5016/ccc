# -*- encoding: utf-8 -*-

require 'logger'
require 'mongo'

#= fetch_url_list にアクセスするためのクラス
#
# anemone が抽出したリンク先のリストを fetch_url_list で管理する．
# その際， URL は処理の状況に応じてステータスを属性として持つ
#== URL のステータス
#- WAIT: 処理町（初期状態）
#- SUCCESS: 項目抽出処理の正常終了
#- ERROR: 項目抽出処理の異常終了
class FetchUrlListDao
  DB_NAME = "character_code_crawler"
  COLLECTION_NAME = "fetch_url_list"

  # プライオリティ
  SEED = 1
  OTHER = 2
  
  # ステータス
  WAIT = 1
  DONE = 2
  ERROR = 3
  
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log

  # DB に接続し ，コレクション "fetch_url_list" オブジェクトを生成する
  def get_collection()
    connection = Mongo::Connection.new("168.63.201.238", 27017)
    db = connection.db(DB_NAME)
    coll = db.collection(COLLECTION_NAME)
  end

  # 既に登録済みの URL はスキップし，未登録の URL のみインサート．
  def skip_or_insert(link_list, priority)
    coll = get_collection()
    list_size = link_list.size
    link_list.each {|link|
      link_url = link.to_s
      if exist?(coll,link_url) then
        log.debug "URL[#{link_url}] は既にインサート済みなので，スキップします．"
        list_size -= 1
        next
      end
      link_url = link.to_s
      insert(coll,link_url, WAIT, priority)
    }
    log.info "#{list_size} 件のURLをインサートしました．"
  end

  # fetch_url_list にリンク先のリストをインサートする
  def insert(coll, url, status, priority)
    log.info "#{COLLECTION_NAME} に URL[#{url}] をインサートします．"
    doc = {'url' => url,
      'priority' => priority,
      'status' => status,
      'create_ts' => Time.now,
      'update_ts' => Time.now}
    coll.insert(doc)
    log.debug "インサート完了"
  end

  # ドキュメントのステータスを更新する
  def update_status(url, status)
    coll = get_collection()
    coll.update({"url" => url}, {"$set" => {"status" => status}})
    log.info "URL[#{url}] のステータスを #{status} に更新しました．"
  end

  # 引数の URL がコレクション内に存在しているか
  def exist?(coll, url)
    doc = coll.find_one("url" => url)
    if doc.to_s == "" then
      log.debug "URL[#{url}] は #{COLLECTION_NAME} 内に存在しません．"
      return false
    end
    log.info "URL[#{url}] は #{COLLECTION_NAME} 内に既に存在します．"
    return true
  end

  # status == WAIT のドキュメントの URL フィールドを返す
  def get_waiting_url
    coll = get_collection
    doc = coll.find_one("status" => WAIT, "priority" => SEED)
    return doc["url"] if doc.to_s == ""
    doc = coll.find_one("status" => WAIT)
    return doc["url"] if doc.to_s == ""
  end

  # status == WAIT の条件でドキュメントを取得し，
  # 処理待ちの URL が存在するかを判断
  def exist_waiting_url?
    coll = get_collection
    log.debug "#{COLLECTION_NAME} に処理待ち URL があるか確認します．"
    doc = coll.find_one("status" => WAIT)
    if doc.to_s == "" then
      log.info "#{COLLECTION_NAME} に処理待ちの URL はありません．"
      return false
    end
    return true
  end

  # 1つの URL について，その URL が抽出の対象かを判断する．
  def skip?(url)
    coll = get_collection()
    if exist?(coll, url) then
      doc = coll.find_one("url" => url)
      status = doc["status"]
      if status != WAIT then
        log.info "URL[#{url}], status[#{status}]"
        log.info "抽出処理を終えた URL です．スキップします"
        return true
      end
    end
    return false
  end

end