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
  
  FLASH_TYPES = [:error, :warning, :success, :message]

  def display_flash(type = nil)
    html = ""

    if type.nil?
      FLASH_TYPES.each { |name| html << display_flash(name) }
    else
      return flash[type].blank? ? "" : "<div class=\"#{type}\">#{flash[type]}</div>"
    end

    html
  end
  
  def display_message(msg, type = :notice)
    return "" if msg.blank?
    "<div class=\"#{type.to_s}\">#{msg}</div>"
  end
  
  # build a place search route
  # note: searching can only be done by city, zip or neighborhood
  def build_search_route(where, options={})
    case where
    when 'city'
      url_for(:action => 'index', :country => options[:country], :state => options[:state], :city => options[:city], :what => options[:what])
    when 'zip'
      url_for(:action => 'index', :country => options[:country], :state => options[:state], :zip => options[:zip], :what => options[:what])
    when 'neighborhood'
      url_for(:action => 'index', :country => options[:country], :state => options[:state], :city => options[:city], 
              :neighborhood => options[:neighborhood], :what => options[:what])
    else
      raise ArgumentError, "no route for #{where}"
    end
  end
  
  def infer_locality_route(name, options={})
    # map name to a specific locality object
    locality = options.values.compact.find { |o| o ? o.name == name : false }
    return '' if locality.blank?
    # build route using locality object
    build_locality_route(locality, options)
  end
  
  def build_locality_route(locality, options={})
    case locality.class.to_s
    when 'Country'
      url_for(:action => 'country', :country => options[:country])
    when 'State'
      url_for(:action => 'state', :country => options[:country], :state => options[:state])
    when 'City'
      url_for(:action => 'city', :country => options[:country], :state => options[:state], :city => options[:city])
    when 'Zip'
      url_for(:action => 'zip', :country => options[:country], :state => options[:state], :zip => options[:zip])
    else
      ''
    end
  end
  
end
