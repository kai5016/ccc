# -*- encoding: utf-8 -*-

#-- ページの項目を定義
#
class PageInfo
  attr_accessor :url, :charset, :act_charset, :body, :title, :link_list
  def initialize (url=nil, charset=nil,
                  body=nil, title=nil, link_list=nil)
    @url = url
    @charset = charset
    @act_charset = act_charset
    @body = body
    @title = title
    @link_list = link_list
  end
end