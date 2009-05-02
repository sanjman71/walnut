class Community
  
  # import all communities
  def self.import
    # communities = [{:city => "La Grange Highlands", :state => "Illinois"}]

    imported  = 0
    file      = "#{RAILS_ROOT}/data/communities.txt"
    FasterCSV.foreach(file, :col_sep => '|') do |row|
      city_name, state_code = row
      
      # validate state
      state = State.find_by_code(state_code)
      next if state.blank?
      # skip if city exists
      city  = state.cities.find_by_name(city_name)
      next if city
      
      # create city
      city = state.cities.create(:name => city_name)
      imported += 1
    end
    
    imported
  end
  
end