module NameModule
  def to_param
    self.name.to_s.downcase.gsub(' ', '-')
  end
  
  def to_s
    self.name
  end
end