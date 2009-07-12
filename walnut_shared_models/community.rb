class Community
  
  # import all communities
  def self.import
    City.import(:file => "#{RAILS_ROOT}/data/communities.txt")
  end
  
end