class PageInfo
  attr_accessor :url, :char_code, :name

  def initialize (url, char_code, name)
    @url = url
    @char_code = char_code
    @name = name
  end
end