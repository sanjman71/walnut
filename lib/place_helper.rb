class PlaceHelper
  
  def self.add_place(hash)
    # create location parameters
    state   = State.find_by_name(hash['state'])
    city    = state.cities.find_by_name(hash['city']) if state
    
    if state.blank? or city.blank?
      raise ArgumentError, "missing city or state"
    end

    street_address  = StreetAddress.normalize(hash['street_address'])
    zip             = state.zips.find_by_name(hash['zip'])
    options         = {:street_address => street_address, :city => city, :state => state, :zip => zip, :country => Country.default}

    if hash['lat'] and hash['lng']
      options.merge!(:lat => hash['lat'], :lng => hash['lng'])
    end
    
    # create location
    location = Location.create(options)
    
    raise ArgumentError if !location.valid?
    
    # add lat/lng
    location.geocode_latlng
    
    # create place
    place = Place.create(:name => hash['name'])
    place.locations.push(location)
    
    location
  end
  
end