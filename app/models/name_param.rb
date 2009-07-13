module NameParam
  def to_param
    # use code first, then use name
    if self.respond_to?(:code)
      self.code.to_s.downcase
    else
      self.name.to_s.downcase.gsub(' ', '-')
    end
  end
  
  def to_s
    self.name
  end
end