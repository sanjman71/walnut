class LocalityError < StandardError; end
  
class Locality
  include Geokit::Mappable
  
  def self.resolve(s)
    begin
      geoloc = geocode(s)
      
      if geoloc.provider == 'google'
        case geoloc.precision
        when 'country'
          # find database object
          object = Country.find_by_code(geoloc.country_code)
        when 'state'
          # find database object, geoloc state is the state code, e.g. "IL"
          object = State.find_by_code(geoloc.state)
        when 'city'
          # find state database object
          state   = State.find_by_code(geoloc.state)
          # find city from state
          object  = state.cities.find_by_name(geoloc.city)
        when 'zip'
          # find state database object
          state   = State.find_by_code(geoloc.state)
          # find zip from state
          object  = state.zips.find_by_name(geoloc.zip)
        end
        
        return object
      end
    rescue
      return nil
    end
    
    return nil
  end
  
  # validate the specified city or zip
  def self.validate(state, type, name)
    raise ArgumentError, "state required" if state.blank? or !state.is_a?(State)
    
    case type.to_s.titleize
    when 'City'
      s       = "#{name} #{state.name}"
      geoloc  = geocode(s)
    when 'Zip'
      s       = "#{state.name} #{name}"
      geoloc  = geocode(s)
    else
      raise ArgumentError, "invalid type #{type}"
    end
    
    if geoloc.provider == 'google'
      if geoloc.precision == type.to_s.downcase
        # create city or zip
        object = Kernel.const_get(type.to_s.titleize).create(:name => name, :state => state, :lat => geoloc.lat, :lng => geoloc.lng)
      else
        raise LocalityError, "invalid #{type}"
      end
    end
    
    return object
  end
end