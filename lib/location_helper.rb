class LocationHelper
  
  # merge the specified set of locations, keeping the first location in the collection
  def self.merge_locations(locations)
    return nil if locations.blank?
    return locations.first if locations.size == 1
    
    location  = locations.delete_at(0)
    company   = location.company
    
    add_tags  = []
     
    # puts "*** keeping location: #{location.company_name}:#{location.id}"
    
    locations.each do |remove_location|
      # puts "*** removing location: #{remove_location.name}:#{remove_location.id}"
      
      remove_location.companies.each do |remove_company|
        # merge tags
        if !remove_company.tag_list.blank?
          company.tag_list.add(remove_company.tag_list)
          company.save
        end
        
        # remove company
        remove_company.destroy
      end
      
      # merge location phone numbers
      remove_location.phone_numbers.each do |lp|
        # destroy phone before merging it
        lp.destroy
        location.phone_numbers.push(PhoneNumber.new(:name => lp.name, :address => lp.address))
      end
      
      # merge location sources
      remove_location.location_sources.each do |ls|
        location.location_sources.push(LocationSource.new(:location => @location, :source_id => ls.source_id, :source_type => ls.source_type))
        ls.destroy
      end
      
      # remove location
      remove_location.destroy
    end
  end
  
end