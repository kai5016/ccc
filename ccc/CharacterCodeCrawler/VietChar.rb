# -*- encoding: utf-8 -*-

module VietChar
  VIET_CHARS = [
    "Ả", "Ã", "Ạ",
    "ả", "ã", "ạ",
    "Ằ", "Ẳ", "Ẵ", "Ắ", "Ặ",
    "ằ", "ẳ", "ẵ", "ắ", "ặ",
    "Ầ", "Ẩ", "Ẫ", "Ấ", "Ậ",
    "ầ", "ẩ", "ẫ", "ấ", "ậ",
    "Ẻ", "Ẽ", "Ẹ",
    "ẻ", "ẽ", "ẹ",
    "Ề", "Ể", "Ễ", "Ế", "Ệ",
    "ề", "ể", "ễ", "ế", "ệ",
    "Ỉ", "Ĩ", "Ị",
    "ỉ", "ĩ", "ị",
    "Ỏ", "Õ", "Ọ",
    "ỏ", "õ", "ọ",
    "Ồ", "Ổ", "Ỗ", "Ố", "Ộ",
    "ồ", "ổ", "ỗ", "ố", "ộ",
    "Ờ", "Ở", "Ỡ", "Ớ", "Ợ",
    "ờ", "ở", "ỡ", "ớ", "ợ",
    "Ủ", "Ũ", "Ụ",
    "ủ", "ũ", "ụ",
    "Ư", "Ừ", "Ử", "Ữ", "Ứ", "Ự",
    "ừ", "ử", "ữ", "ứ", "ự",
    "Ỷ", "Ỹ", "Ỵ",
    "ỷ", "ỹ", "ỵ",
    "Đ", "đ"
  ]
  VIET_REGEXP = Regexp.union(VIET_CHARS)
  viet_char_google = {
    "À" => "%C3%80", "Ả" => "%E1%BA%A2", "Ã" => "%C3%83", "Á" => "%C3%81", "Ạ" => "%E1%BA%A0",
    "Ă" => "%C4%82", "Ằ" => "%E1%BA%B0", "Ẳ" => "%E1%BA%B2", "Ẵ" => "%E1%BA%B4", "Ắ" => "%E1%BA%AE", "Ặ" => "%E1%BA%B6",
    "Â" => "%C3%82", "Ầ" => "%E1%BA%A6", "Ẩ" => "%E1%BA%A8", "Ẫ" => "%E1%BA%AA", "Ấ" => "%E1%BA%A4", "Ậ" => "%E1%BA%AC",
    "Đ" => "%C4%90",
    "È" => "%C3%88", "Ẻ" => "%E1%BA%BA", "Ẽ" => "%E1%BA%BC", "É" => "%C3%89", "Ẹ" => "%E1%BA%B8",
    "Ê" => "%C3%8A", "Ề" => "%E1%BB%80", "Ể" => "%E1%BB%82", "Ễ" => "%E1%BB%84", "Ế" => "%E1%BA%BE", "Ệ" => "%E1%BB%86",
    "Ô" => "%C3%B4", "Ồ" => "%E1%BB%92", "Ổ" => "%E1%BB%94", "Ỗ" => "%E1%BB%96", "Ố" => "%E1%BB%90", "Ộ" => "%E1%BB%98",
    "Ơ" => "%C6%A1", "Ờ" => "%E1%BB%9C", "Ở" => "%E1%BB%9E", "Ỡ" => "%E1%BB%A0", "Ớ" => "%E1%BB%9A", "Ợ" => "%E1%BB%A2",
    "Ù" => "%C3%99", "Ủ" => "%E1%BB%A6", "Ũ" => "%C5%A8", "Ú" => "%C3%9A", "Ụ" => "%E1%BB%A4",
    "Ư" => "%C6%AF", "Ừ" => "%E1%BB%AA", "Ử" => "%E1%BB%AC", "Ữ" => "%E1%BB%AE", "Ứ" => "%E1%BB%A8", "Ự" => "%E1%BB%B0",
    "Ì" => "%C3%8C", "Ỉ" => "%E1%BB%88", "Ĩ" => "%C4%A8", "Í" => "%C3%8D", "Ị" => "%E1%BB%8A",
    "Ỳ" => "%E1%BB%B2", "Ỷ" => "%E1%BB%B6", "Ỹ" => "%E1%BB%B8", "Ý" => "%C3%9D", "Ỵ" => "%E1%BB%B4",
    "à" => "%C3%80", "ả" => "%E1%BA%A2", "ã" => "%C3%83", "á" => "%C3%81", "ạ" => "%E1%BA%A0",
    "ă" => "%C4%83", "ằ" => "%E1%BA%B0", "ẳ" => "%E1%BA%B2", "ẵ" => "%E1%BA%B4", "ắ" => "%E1%BA%AE", "ặ" => "%E1%BA%B6",
    "â" => "%C3%A2", "ầ" => "%E1%BA%A6", "ẩ" => "%E1%BA%A8", "ẫ" => "%E1%BA%AA", "ấ" => "%E1%BA%A4", "ậ" => "%E1%BA%AC",
    "đ" => "%C4%91",
    "è" => "%C3%88", "ẻ" => "%E1%BA%BA", "ẽ" => "%E1%BA%BC", "é" => "%C3%89", "ẹ" => "%E1%BA%B8",
    "ê" => "%C3%AA", "ề" => "%E1%BB%80", "ể" => "%E1%BB%82", "ễ" => "%E1%BB%84", "ế" => "%E1%BA%BE", "ệ" => "%E1%BB%86",
    "ò" => "%C3%92", "ỏ" => "%E1%BB%8E", "õ" => "%C3%95", "ó" => "%C3%93", "ọ" => "%E1%BB%8C",
    "ô" => "%C3%B4", "ồ" => "%E1%BB%92", "ổ" => "%E1%BB%94", "ỗ" => "%E1%BB%96", "ố" => "%E1%BB%90", "ộ" => "%E1%BB%98",
    "ơ" => "%C6%A1", "ờ" => "%E1%BB%9C", "ở" => "%E1%BB%9E", "ỡ" => "%E1%BB%A0", "ớ" => "%E1%BB%9A", "ợ" => "%E1%BB%A2",
    "ư" => "%C6%B0", "ừ" => "%E1%BB%AA", "ử" => "%E1%BB%AC", "ữ" => "%E1%BB%AE", "ứ" => "%E1%BB%A8", "ự" => "%E1%BB%B0",
    "ì" => "%C3%8C", "ỉ" => "%E1%BB%88", "ĩ" => "%C4%A8", "í" => "%C3%8D", "ị" => "%E1%BB%8A",
    "Ò" => "%C3%92", "Ỏ" => "%E1%BB%8E", "Õ" => "%C3%95", "Ó" => "%C3%93", "Ọ" => "%E1%BB%8C",
    "ù" => "%C3%99", "ủ" => "%E1%BB%A6", "ũ" => "%C5%A8", "ú" => "%C3%9A", "ụ" => "%E1%BB%A4",
    "ỳ" => "%E1%BB%B2", "ỷ" => "%E1%BB%B6", "ỹ" => "%E1%BB%B8", "ý" => "%C3%9D", "ỵ" => "%E1%BB%B4",
  }
  
  def VietChar.viet?(str)
    str.gsub!("Tiếng Việt", "")
    return VIET_REGEXP === str 
  end
  
end