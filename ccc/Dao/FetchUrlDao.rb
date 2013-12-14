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
  def skip_or_insert(link_list, priority, depth = 0)
    list_size = link_list.size
    link_list.each {|link|
      link_url = link.to_s
      if exist?(link_url) then
        log.debug "URL[#{link_url}] は既にインサート済みなので，スキップします．"
        list_size -= 1
        next
      end
      insert(link_url, FetchUrl::WAIT, priority, depth)
    }
    log.info "#{list_size} 件のURLをインサートしました．"
    puts "#{list_size} URLs are inserted．"
  end

  # fetch_url_list にリンク先のリストをインサートする
  def insert(url, status = FetchUrl::WAIT, priority = FetchUrl::OTHER, depth = 0)
    log.info "Insert a URL[#{url}]."
    fetch_url = FetchUrl.new(:url => url,
                             :priority => priority,
                             :status => status,
                             :depth => depth)
    fetch_url.save
    log.debug "インサート完了"
  end

  # ドキュメントのステータスを更新する
  def update_status(url, status)
    fetch_url = FetchUrl.where(:url => url).first
    fetch_url.status = status
    fetch_url.save
    log.info "URL[#{url}] のステータスを #{status} に更新しました．"
  end

  # Error フィールドを追加する
  def update_error(url)
    fetch_url = FetchUrl.where(:url => url).first
    fetch_url.has_error = true
    fetch_url.save
    log.info "URL[#{url}] に\"has_error\" フィールドを追加しました．"
  end

  # 引数の URL がコレクション内に存在しているか
  def exist?(url)
    fetch_url = FetchUrl.where(:url => url).first
    if fetch_url.to_s == "" then
      log.debug "URL[#{url}] は存在しません．"
      return false
    end
    log.info "URL[#{url}] は既に存在します．"
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
    log.debug "処理待ち URL があるか確認します．"
    fetch_url = FetchUrl.where("status" => FetchUrl::WAIT).first
    if fetch_url == nil then
      log.info "処理待ちの URL はありません．"
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
      log.debug "URL[#{url}] は未処理です．"
      return false
    end
    log.info "URL[#{url}] はステータス[#{status}] で処理されました．"
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
