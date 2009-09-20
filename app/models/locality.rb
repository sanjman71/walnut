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
  
  # check the specified city/zip in the specified state
  # throws a LocalityError exception if the city/zip does not exist in the specified state
  def self.check(state, type, name)
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
  
  # find the specified locality in the database, and return nil if its not there
  # - "Chicago, IL" should map to the city object 'Chicago'
  def self.search(s, options={})
    # parse options
    log   = options[:log] ? options[:log] : false

    match = s.match(/([A-Za-z ]+),{0,1} ([A-Z][A-Z])/)

    if match
      city_name   = match[1]
      state_code  = match[2]

      # search database for city and state
      state = State.find_by_code(state_code)
      return nil if state.blank?
      city  = state.cities.find_by_name(city_name)

      if log
        if city
          RAILS_DEFAULT_LOGGER.debug("*** mapped #{s} to #{city.name}")
        else
          RAILS_DEFAULT_LOGGER.debug("xxx could not map #{s} to a city")
        end
      end

      city
    else
      nil
    end
  end

  # set events count using sphinx facets for the specified locality klass
  def self.set_event_counts(klass)
    case klass.to_s.downcase
    when 'city'
      facet_string  = :city_id
    when 'zip'
      facet_string  = :zip_id
    when 'neighborhood'
      facet_string  = :neighborhood_ids
    else
      raise ArgumentError, "invalid klass #{klass}"
    end

    geo_event_hash = Appointment.facets(:facets => facet_string)[facet_string.to_sym]
    geo_event_hash.each_pair do |klass_id, events_count|
      next unless object = klass.find_by_id(klass_id)
      object.events_count = events_count
      object.save
    end

    # return the number of objects updated
    geo_event_hash.keys.size
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