class PageInfo
  attr_accessor :url, :char_code, :name, :title

  def initialize (url, char_code, name)
    @url = url
    @char_code = char_code
    @name = name
    @title = title
  end
end