# -*- encoding: utf-8 -*-

require 'logger'
require 'mongoid'
require 'uri'

require_relative '.\conf'

class InvalidDomain
  include Mongoid::Document
  include Mongoid::Timestamps

  field :domain
end

class InvalidDomainDao
  def initialize(log = nil)
    @log = log || Logger.new("crawler.log")
  end
  attr_reader :log

  # DB に接続し ，コレクション "fetch_url_list" オブジェクトを生成する
  Mongoid.configure  do |conf|
    conf.master = Mongo::Connection.new(CONNECT_TO, 27017).db(DB_NAME)
  end

  # 引数の URL がコレクション内に存在しているか
  def exist?(url)
    domain = URI(url).host
    invalid_domain = InvalidDomain.where(:domain => domain).first
    if invalid_domain.nil?
      log.debug "URL[#{url}] does not exist"
      return false
    end
    log.info "URL[#{url}] already exist．"
    return true
  end

  # fetch_url_list にリンク先のリストをインサートする
  def insert(url)
    domain = URI(url).host
    log.info "Insert a URL[#{url}]'s domain[#{domain}]."
    invalid_domain = InvalidDomain.new(:domain => domain)
    invalid_domain.save
    log.debug "Completed."
  end
  
end
