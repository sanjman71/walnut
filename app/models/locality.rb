class LocalityError < StandardError; end
  
class Locality
  include Geokit::Mappable
  
  def self.resolve(s)
    begin
      geoloc = geocode(s)
      
      case geoloc.provider
      when 'google', 'yahoo'
        case geoloc.precision
        when 'country'
          # find database object
          object = Country.find_by_code(geoloc.country_code)
        when 'state'
          # map state codes
          map_state_codes(geoloc)
          # find database object, geoloc state is the state code, e.g. "IL"
          object = State.find_by_code(geoloc.state)
        when 'city'
          # map state codes
          map_state_codes(geoloc)
          # find state database object
          state   = State.find_by_code(geoloc.state)
          # find city from state
          object  = state.cities.find_by_name(geoloc.city)
        when 'zip'
          # map state codes
          map_state_codes(geoloc)
          # find state database object
          state = State.find_by_code(geoloc.state)

          if geoloc.provider == 'yahoo'
            # yahoo returns a zip precision for cities and zips
            if geoloc.zip.blank?
              # its a city - find city from state
              object = state.cities.find_by_name(geoloc.city)
            else
              # its a zip - find zip from state
              object = state.zips.find_by_name(geoloc.zip)
            end
          else
            # google zip really means a zip - find zip from state
            object = state.zips.find_by_name(geoloc.zip)
          end
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
      raise ArgumentError, "invalid type #{type}, #{name}"
    end

    # find class object we are trying to find or create
    klass  = Kernel.const_get(type.to_s.titleize)
    
    if geoloc.provider == 'google'
      # the google geocoder
      if geoloc.precision == type.to_s.downcase
        # find or create city or zip
        # use the geoloc name as the 'official' name, unless its blank, which allows mis-spellings to be normalized by the geocoder
        name   = geoloc.send(type.to_s.downcase).blank? ? name : geoloc.send(type.to_s.downcase)
        object = klass.find_by_name_and_state_id(name, state.id) || klass.create(:name => name, :state => state, :lat => geoloc.lat, :lng => geoloc.lng)
      else
        raise LocalityError, "invalid #{type}, #{name}"
      end
    elsif geoloc.provider == 'yahoo'
      # the yahoo geocoder
      case type.to_s.downcase
      when 'city'
        # yahoo precision field is 'city' or 'zip', city must be valid, state code must match
        if (geoloc.precision == type.to_s.downcase or geoloc.precision == 'zip') and !geoloc.send(type.to_s.downcase).blank? and geoloc.state == state.code
          # use the geoloc name as the 'official' name
          name   = geoloc.send(type.to_s.downcase)
          object = klass.find_by_name_and_state_id(name, state.id) || klass.create(:name => name, :state => state, :lat => geoloc.lat, :lng => geoloc.lng)
        end
      when 'zip'
        # yahoo precision field is 'zip', zip must be valid, state code must match
        if geoloc.precision == type.to_s.downcase and !geoloc.send(type.to_s.downcase).blank? and geoloc.state == state.code
          name   = geoloc.send(type.to_s.downcase)
          object = klass.find_by_name_and_state_id(name, state.id) || klass.create(:name => name, :state => state, :lat => geoloc.lat, :lng => geoloc.lng)
        end
      else
        raise LocalityError, "invalid #{type}, #{name}"
      end
    end
    
    return object
  end
  
  protected
  
  # map special state codes
  def self.map_state_codes(geoloc)
    return geoloc if geoloc.blank? or geoloc.state.blank?
    
    case geoloc.state.titleize
    when "N Carolina"
      geoloc.state = "NC"
    when "S Carolina"
      geoloc.state = "SC"
    when "S Dakota"
      geoloc.state = "SD"
    when "N Dakota"
      geoloc.state = "ND"
    when "Rhode Isl"
      geoloc.state = "RI"
    when "W Virginia"
      geoloc.state = "WV"
    end
    
    geoloc
  end
end