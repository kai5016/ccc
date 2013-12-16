# -*- encoding: utf-8 -*-

require 'logger'
require 'mongoid'
require_relative '.\conf'

#= コレクション fetch_urls の定義
#
# anemone が抽出したリンク先のリストを fetch_urls で管理する．
# その際， URL は処理の状況に応じてステータスを属性として持つ
#== URL のステータス
#- WAIT: 処理町（初期状態）
#- SUCCESS: 項目抽出処理の正常終了
#- ERROR: 項目抽出処理の異常終了
class FetchUrl
  include Mongoid::Document
  include Mongoid::Timestamps

  # プライオリティ
  SEED = 1
  OTHER = 2
  # ステータス
  WAIT = 1
  DONE = 2
  EncodingError = 3
  NONE_VIET_CHAR = 4
  INVALID_DOMAIN = 5
  UnkownERROR = 9
    
  field :url
  field :depth
  field :status, :default => WAIT
  field :priority, :default => OTHER
  field :has_error, :default => false
end

#= fetch_urls にアクセスするためのクラス
class FetchUrlDao
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log

  # DB に接続し ，コレクション "fetch_url_list" オブジェクトを生成する
  Mongoid.configure  do |conf|
  conf.master = Mongo::Connection.new(CONNECT_TO, 27017).db(DB_NAME)
  end

  # 既に登録済みの URL はスキップし，未登録の URL のみインサート．
  def skip_or_insert(url, priority, depth = 0)
    if exist?(url)
      log.debug "URL[#{url}] is skipped"
      return
    end
    insert(url, FetchUrl::WAIT, priority, depth)
  end

  # fetch_url_list にリンク先のリストをインサートする
  def insert(url, status = FetchUrl::WAIT, priority = FetchUrl::OTHER, depth = 0)
    log.info "Insert a URL[#{url}]."
    fetch_url = FetchUrl.new(:url => url,
                             :priority => priority,
                             :status => status,
                             :depth => depth)
    fetch_url.save
    log.debug "Completed."
  end

  # ドキュメントのステータスを更新する
  def update_status(url, status)
    fetch_url = FetchUrl.where(:url => url).first
    fetch_url.status = status
    fetch_url.save
    log.info "Updated status to STATUS[#{status}]: URL[#{url}]"
  end

  # Error フィールドを追加する
  def update_error(url)
    fetch_url = FetchUrl.where(:url => url).first
    fetch_url.has_error = true
    fetch_url.save
    log.info "URL[#{url}] Add a field \"has_error\""
  end

  # 引数の URL がコレクション内に存在しているか
  def exist?(url)
    fetch_url = FetchUrl.where(:url => url).first
    if fetch_url.nil?
      log.debug "URL[#{url}] does not exist"
      return false
    end
    log.info "URL[#{url}] already exist．"
    return true
  end

  # depth の値が最も小さい status == WAIT のドキュメントの URL フィールドを返す
  def get_waiting_url
    fetch_url = FetchUrl.where("status" => FetchUrl::WAIT).
                          and("priority" => FetchUrl::SEED).first
     if fetch_url != nil
       log.info "URL#{fetch_url.url}, PRIORITY#{fetch_url.priority}"
       return fetch_url
     end
     fetch_url = FetchUrl.where("status" => FetchUrl::WAIT).
                          and("priority" => FetchUrl::OTHER).
                          and("has_error" => false).first
     if fetch_url != nil
       log.info "URL#{fetch_url.url}, PRIORITY#{fetch_url.priority}, HAS_ERROR#{fetch_url.has_error}"
       return fetch_url
     end
     fetch_url = FetchUrl.where("status" => FetchUrl::WAIT).
                          and("priority" => FetchUrl::OTHER).first
     if fetch_url != nil
       log.info "URL#{fetch_url.url}, PRIORITY#{fetch_url.priority}"
       return fetch_url
     end
  end
 
  # status == WAIT の条件でドキュメントを取得し，
  # 処理待ちの URL が存在するかを判断
  def exist_waiting_url?
    log.debug "Check waiting URL exists"
    fetch_url = FetchUrl.where("status" => FetchUrl::WAIT).first
    if fetch_url == nil then
      log.info "There is no wating URL."
      return false
    end
    return true
  end

  # 1つの URL について，その URL が抽出の対象かを判断する．
  def skip?(url)
    fetch_url = FetchUrl.where(:url => url).first
    return true if fetch_url == nil  
    status = fetch_url.status
    if status == FetchUrl::WAIT
      log.debug "URL[#{url}] is waiting for fetch"
      return false
    end
    log.info "URL[#{url}]'s status is [#{status}] "
    return true
  end
  
  # Queue の振る舞いをするためのメソッド
  def enq(url, depth)
    insert(url, FetchUrl::WAIT, FetchUrl::OTHER, depth) if !exist?(url)
  end
  def deq
    fetch_url = get_waiting_url
    return [fetch_url.url, fetch_url.depth]
  end
  def empty?
    exist_waiting_url?
  end
  def num_waiting
    FetchUrl.where("status" => FetchUrl::WAIT).
             and("priority" => FetchUrl::OTHER).
             and("has_error" => false).count
  end

end
