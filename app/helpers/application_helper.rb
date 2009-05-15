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
  
  # build search route based on the klass parameter
  # note: searching can only be done by city, zip or neighborhood
  def build_search_route(klass, where, options={})
    case klass.to_s.downcase
    when 'location', 'locations', 'place', 'places'
      klass = 'locations'
    when 'event', 'events'
      klass = 'events'
    when 'search'
      klass = 'search'
    else
      raise Exception, "invalid klass #{klass} for search route"
    end
    
    case where
    when 'city'
      build_city_search_route(klass, options[:country], options[:state], options[:city], options)
      # url_for(:controller => controller, :action => 'index', :country => options[:country], :state => options[:state], :city => options[:city], 
      #         :tag => options[:tag], :what => options[:what])
    when 'zip'
      build_zip_search_route(klass, options[:country], options[:state], options[:zip], options)
      # url_for(:controller => controller, :action => 'index', :country => options[:country], :state => options[:state], :zip => options[:zip], 
      #         :tag => options[:tag], :what => options[:what])
    when 'neighborhood'
      build_neighborhood_search_route(klass, options[:country], options[:state], options[:city], options[:neighborhood], options)
      # url_for(:controller => controller, :action => 'index', :country => options[:country], :state => options[:state], :city => options[:city], 
      #         :neighborhood => options[:neighborhood], :tag => options[:tag], :what => options[:what])
    else
      raise ArgumentError, "no route for #{where}"
    end
  end
  
  def infer_locality_route(name, options={})
    # map name to a specific locality object
    locality = options.values.flatten.compact.find { |o| o ? o.name == name : false }
    return '' if locality.blank?
    # build route using locality object
    build_locality_route(locality, options)
  end
  
  def build_locality_route(locality, options={})
    klass = 'search'
    
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
      "/tag/#{options[:tag]}"
    elsif options[:what]
      "/#{options[:what]}"
    else
      ""
    end
  end

end
