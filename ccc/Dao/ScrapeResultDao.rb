# -*- encoding: utf-8 -*-

require 'logger'
require 'mongo'

#= DB "character_code_crawler" のコレクション "scrape_result" にアクセスするためのクラス
#
# anemone が抽出した項目を  scrape_result で管理する．
class ScrapeResultDao
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log

  COLLECTION_NAME = "scrape_result"

  # DB に接続し ，コレクション "scrape_result" オブジェクトを生成する
  def get_collection
    connection = Mongo::Connection.new("168.63.201.238", 27017)
    db = connection.db('character_code_crawler')
    coll = db.collection(COLLECTION_NAME)
  end

  # 以前に抽出結果が登録された URL なのか，新規の URL なのかによって
  # ドキュメントを挿入するか更新するかを判断する
  def insert_or_update(page_info)
    coll = get_collection
    if exist?(coll, page_info.url) then
      update(coll, page_info)
    else
      insert(coll, page_info)
    end
  end

  # コレクション内に対象の URL が存在するか
  def exist?(coll, url)
    doc = coll.find_one("url" => url)
    if doc.to_s == "" then
      return false
    end
    log.info "URL[#{url}] は既に #{COLLECTION_NAME} に抽出結果が登録されています"
    return true
  end

  # コレクション "scrape_result"に page_info を挿入
  def insert(coll, page_info)
    log.info "#{COLLECTION_NAME} に URL[#{page_info.url}] の抽出結果を挿入します．"
    begin
      doc = {'url' => page_info.url,
             'title' => page_info.title,
             'charset' => page_info.charset,
             'body' => page_info.body,
             'create_ts' => Time.now,
             'update_ts' => Time.now}
      coll.insert(doc)
      log.info "#{COLLECTION_NAME} に URL[#{page_info.url}] の抽出結果を挿入しました．"
    rescue BSON::InvalidStringEncoding => ex
      log.error("URL[#{page_info.url}]の本文抽出中にエコーディングエラーが発生しました．
                 page_info.charset[#{page_info.charset}]\n#{ex}")
      raise ex      
    end
  end

  # page_info の内容を更新
  # 他クラスから単独でこのメソッドを使用する際は以下のようになる．
  #
  # update(scrape_result_dao.get_collection, page_info)
  #
  def update(coll, page_info)
    log.debug "#{COLLECTION_NAME} の URL[#{page_info.url}] の抽出結果を更新します．"
    coll.update({"url" => page_info.url},
    {"$set" => {'title' => page_info.title,
      'charset' => page_info.charset,
      'body' => page_info.body,
      'update_ts' => Time.now}})
    log.info "#{COLLECTION_NAME} の URL[#{page_info.url}] の抽出結果を更新しました．"
  end

  # DB から 全てのドキュメント を取得
  def get_all_documents
    coll = get_collection
    docs = coll.find
  end

  # ドキュメントが正規化されているかのフラグをセットする
  def set_normalized_flg(boolean, url)
    coll = get_collection
    coll.update({"url" => url},
    {"$set" => {'normalized_flg' => boolean,
      'update_ts' => Time.now}})
    log.info "#{COLLECTION_NAME} の URL[#{url}] の正規化フラグを更新しました．"
  end

  # normalized_flg に従ってドキュメントを取得する
  def find_by_normalized_flg(boolean)
    coll = get_collection
    docs = coll.find({"normalized_flg" => boolean})
  end

  # normalized_flg に従ってドキュメントを取得する
  def find_one_by_normalized_flg(boolean)
    coll = get_collection
    doc = coll.find_one({"normalized_flg" => boolean})
  end

  # url を条件にしてドキュメントを取得する
  def find_by_url(url)
    coll = get_collection
    docs = coll.find({"url" => url})
  end
end