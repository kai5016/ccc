# -*- encoding: utf-8 -*-

require 'logger'
require 'mongoid'

class FetchUrl
  include Mongoid::Document
  include Mongoid::Timestamps

  # プライオリティ
  SEED = 1
  OTHER = 2
  # ステータス
  WAIT = 1
  DONE = 2
  ERROR = 3

  field :url
  field :status, :default => WAIT
  field :priority, :default => OTHER
end

#= fetch_url_list にアクセスするためのクラス
#
# anemone が抽出したリンク先のリストを fetch_url_list で管理する．
# その際， URL は処理の状況に応じてステータスを属性として持つ
#== URL のステータス
#- WAIT: 処理町（初期状態）
#- SUCCESS: 項目抽出処理の正常終了
#- ERROR: 項目抽出処理の異常終了
class FetchUrlDao
  DB_NAME = "character_code_crawler"
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log

  # DB に接続し ，コレクション "fetch_url_list" オブジェクトを生成する
  Mongoid.configure  do |conf|
    conf.master = Mongo::Connection.new("168.63.201.238", 27017).db(DB_NAME)
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
    puts "#{list_size} 件のURLをインサートしました．"
  end

  # fetch_url_list にリンク先のリストをインサートする
  def insert(url, status = FetchUrl::WAIT, priority = FetchUrl::OTHER, depth = 0)
    log.info "URL[#{url}] をインサートします．"
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

  # status == WAIT のドキュメントの URL フィールドを返す
  def get_waiting_url
    fetch_url = FetchUrl.where("status" => FetchUrl::WAIT).and("priority" => FetchUrl::SEED).first
    return fetch_url.url if fetch_url != nil
    fetch_url = FetchUrl.where("status" => FetchUrl::WAIT).and("priority" => FetchUrl::OTHER).first
    return fetch_url.url
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

end
