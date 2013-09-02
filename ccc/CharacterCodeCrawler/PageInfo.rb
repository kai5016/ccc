class PageInfo
  attr_accessor :url, :char_code, :body, :title, :link_list
  def initialize (url=nil, char_code=nil, body=nil, title=nil, link_list=nil)
    @url = url
    @char_code = char_code
    @body = body
    @title = title
    @link_list = link_list
  end
end