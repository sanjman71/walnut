class BigDecimal
  
  def to_url_param
    self.to_s.gsub(".", '')
  end

  # create big decimal from url param string
  def self.from_url_param(s)
    # break up number, add '.' after first 2 digits
    match = s.match(/(-{0,1}[0-9]{2,2})([0-9]+)/)
    BigDecimal.new("#{match[1]}.#{match[2]}")
  end

end