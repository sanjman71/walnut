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
  
  # build search route based on the controller in the current request
  # note: searching can only be done by city, zip or neighborhood
  def build_search_route(klass, where, options={})
    # map klass to a controller
    case klass.to_s.downcase
    when 'location', 'place'
      controller = 'places'
    when 'event'
      controller = 'events'
    when 'search'
      controller = 'search'
    else
      raise Exception, "invalid klass for search route"
    end
    
    case where
    when 'city'
      url_for(:controller => controller, :action => 'index', :country => options[:country], :state => options[:state], :city => options[:city], 
              :tag => options[:tag], :what => options[:what])
    when 'zip'
      url_for(:controller => controller, :action => 'index', :country => options[:country], :state => options[:state], :zip => options[:zip], 
              :tag => options[:tag], :what => options[:what])
    when 'neighborhood'
      url_for(:controller => controller, :action => 'index', :country => options[:country], :state => options[:state], :city => options[:city], 
              :neighborhood => options[:neighborhood], :tag => options[:tag], :what => options[:what])
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
    case locality.class.to_s
    when 'Country'
      url_for(:action => 'country', :country => locality)
    when 'State'
      url_for(:action => 'state', :country => options[:country], :state => locality)
    when 'City'
      url_for(:action => 'city', :country => options[:country], :state => options[:state], :city => locality)
    when 'Zip'
      url_for(:action => 'zip', :country => options[:country], :state => options[:state], :zip => locality)
    when 'Neighborhood'
      url_for(:action => 'neighborhood', :country => options[:country], :state => options[:state], :city => options[:city], :neighborhood => locality)
    else
      ''
    end
  end
  
end
