class LocationHelper
  
  # merge the specified set of locations, keeping the first location in the collection
  def self.merge_locations(locations)
    return nil if locations.blank?
    return locations.first if locations.size == 1
    
    location  = locations.delete_at(0)
    place     = location.place
    
    add_tags  = []
     
    # puts "*** keeping location: #{location.place_name}:#{location.id}"
    
    locations.each do |remove_location|
      # puts "*** removing location: #{remove_location.name}:#{remove_location.id}"
      
      remove_location.places.each do |remove_place|
        # merge tags
        if !remove_place.tag_list.blank?
          place.tag_list.add(remove_place.tag_list)
          place.save
        end
        
        # remove place
        remove_place.destroy
      end
      
      # merge location phone numbers
      remove_location.phone_numbers.each do |lp|
        location.phone_numbers.push(PhoneNumber.new(:name => lp.name, :number => lp.number))
        lp.destroy
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