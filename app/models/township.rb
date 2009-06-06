class Township
  
  # import all townships
  def self.import
    City.import(:file => "#{RAILS_ROOT}/data/townships.txt")
  end
  
end