# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def title(page_title)
    content_for(:title)  { page_title }
  end
  
  def javascript(*files)
    content_for(:javascript) { javascript_include_tag(*files) }
  end

  def stylesheet(*files)
    content_for(:stylesheet) { stylesheet_link_tag(*files) }
  end
  
  def robots(*args)
    @robots = args.join(",")
  end
  
  FLASH_TYPES = [:error, :warning, :success, :message, :notice]

  def display_flash(force = false)
    if force || @flash_displayed.nil? || @flash_displayed == false
      @flash_displayed = true
      render :partial => "shared/flash.html.haml", :object => (flash.nil? ? {} : flash)
    end
  end
  
  def display_message(msg, type = :notice)
    return "" if msg.blank?
    "<div class=\"#{type.to_s}\">#{msg}</div>"
  end
  
  def current_search_locality
    if @city and @state
      "#{@city.name}, #{@state.code}"
    elsif @zip and @state
      "#{@state.code} #{@zip.name}"
    else
      ''
    end
  end
  
  def current_search_query
    @query_raw ? @query_raw : "" 
  end
  
  def location_color(location)
    color = "_brown"  # default color
    
    return color if location.blank?
    
    case location.events_count
    when 0
      # location with no events
      color = "_brown"
    else
      # location with events
      color = "_orange"
    end
    color
  end
  
  def location_features(location)
    return [] if location.blank?
    features = ["location"]
    features.push("event") if location.events_count > 0    
    features.sort
  end
  
  def klass_to_word(klass)
    case klass.to_s.downcase
    when 'locations', 'places'
      'locations'
    when 'location', 'place'
      'location'
    when 'events', 'appointments'
      'events'
    when 'event', 'appointment'
      'event'
    when 'search', 'searches'
      'search'
    else
      raise Exception, "invalid klass #{klass} for search route"
    end
  end
  
  # build search route based on the klass parameter
  # note: searching can only be done by city, zip or neighborhood
  def build_search_route(klass, where, options={})
    klass = klass_to_word(klass.pluralize)
    
    case where
    when 'city'
      build_city_search_route(klass, options[:country], options[:state], options[:city], options)
    when 'zip'
      build_zip_search_route(klass, options[:country], options[:state], options[:zip], options)
    when 'neighborhood'
      build_neighborhood_search_route(klass, options[:country], options[:state], options[:city], options[:neighborhood], options)
    else
      raise ArgumentError, "no route for #{where}"
    end
  end
  
  def infer_locality_route(name, options={})
    # map name to a specific locality object
    locality = options.values.flatten.compact.find { |o| o ? o.name == name : false }
    return '' if locality.blank?
    # build route using locality object
    build_locality_route('search', locality, options)
  end
  
  def build_locality_route(klass, locality, options={})
    case locality.class.to_s
    when 'Country'
      build_country_route(klass, locality)
    when 'State'
      build_state_route(klass, options[:country], locality)
    when 'City'
      build_city_route(klass, options[:country], options[:state], locality)
    when 'Zip'
      build_zip_route(klass, options[:country], options[:state], locality)
    when 'Neighborhood'
      build_neighborhood_route(klass, options[:country], options[:state], options[:city], locality)
    else
      ''
    end
  end
  
  # url_for optimizations

  def build_country_route(klass, country)
    "/#{klass}/#{country.to_param}"
  end
  
  def build_state_route(klass, country, state)
    "/#{klass}/#{country.to_param}/#{state.to_param}"
  end
  
  def build_city_route(klass, country, state, city)
    "/#{klass}/#{country.to_param}/#{state.to_param}/#{city.to_param}"
  end
  
  def build_neighborhood_route(klass, country, state, city, neighborhood)
    "/#{klass}/#{country.to_param}/#{state.to_param}/#{city.to_param}/n/#{neighborhood.to_param}"
  end
  
  def build_zip_route(klass, country, state, zip)
    "/#{klass}/#{country.to_param}/#{state.to_param}/#{zip.to_param}"
  end
  
  def build_city_search_route(klass, country, state, city, options={})
    route = "/#{klass}/#{country.to_param}/#{state.to_param}/#{city.to_param}" + build_what_route_path(options)
  end

  def build_zip_search_route(klass, country, state, zip, options={})
    route = "/#{klass}/#{country.to_param}/#{state.to_param}/#{zip.to_param}" + build_what_route_path(options)
  end
  
  def build_neighborhood_search_route(klass, country, state, city, neighborhood, options={})
    route = "/#{klass}/#{country.to_param}/#{state.to_param}/#{city.to_param}/n/#{neighborhood.to_param}" + build_what_route_path(options) 
  end

  def build_what_route_path(options)
    if options[:tag]
      "/tag/#{options[:tag].to_url_param}"
    elsif options[:query]
      "/q/#{options[:query].to_url_param}"
    else
      ""
    end
  end

  # build google image marker path
  def google_marker(color, index)
    "/images/marker" + color + Array('A'..'Z')[index] + ".png"
  end

  # original marker size is 20x34
  def google_marker_size
    "16x27"
  end

  def google_marker_width
    google_marker_size.split("x")[0]
  end

  def google_marker_height
    google_marker_size.split("x")[1]
  end

end
