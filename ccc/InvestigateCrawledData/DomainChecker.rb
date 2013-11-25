# -*- encoding: utf-8 -*-

require '..\Dao\ScrapeResultDao'
require 'uri'

class DomainChecker
  def initialize(log = nil)
    @log = log || Logger.new("crawlData.log")
  end
  attr_reader :log
end

dao = ScrapeResultDao.new
docs = dao.get_all_documents
domain = Hash.new(0)
docs.each{ |doc|
  url = URI(doc["url"])
  domain[url.host] += 1
}

puts domain