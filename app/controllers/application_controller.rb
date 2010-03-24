# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # Make the following methods available to all helpers
  helper_method :has_privilege?, :recommended?, :recommended_by_me?, :ga_events
  
  # AuthenticatedSystem is used by restful_authentication
  include AuthenticatedSystem
  
  # Exception notifier to send emails when we have exceptions
  include ExceptionNotifiable

  include RecommendationsHelper
  include GoogleAnalyticsEventsHelper
  
  include ActionView::Helpers::NumberHelper

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '7c342efc7bc88b372c5913ebad934c5e'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  # Load and cache all user privileges on each call so we don't have to keep checking the database
  before_filter :init_current_privileges

  # Mobile device support
  before_filter :prepare_for_mobile

  # Default application layout
  layout 'home'

  # check user privileges against the pre-loaded memory collection instead of using the database
  def has_privilege?(p, *args)
    authorizable  = args[0]
    user          = args[1] || current_user
    logger.debug("*** checking privilege #{p}, on authorizable #{authorizable ? authorizable.name : ""}, for user #{user ? user.name : ""}")
    return false if current_privileges.blank?
    return current_privileges.include?(p)
  end

  # check if current user has the specified role, on the optional authorizable object
  def has_role?(role_name, authorizable=nil)
    logger.debug("*** checking role #{role_name}, on authorizable #{authorizable ? authorizable.name : ""}, for user #{current_user ? current_user.name : ""}")
    current_roles.include?(role_name)
  end

  def auth_token?
    AuthToken.instance.token == params[:token].to_s
  end

  def current_privileges
    @current_privileges ||= []
  end
  
  def current_roles
    @current_roles ||= []
  end
  
  def ga_events
    @ga_events ||= []
  end

  def init_current_privileges
    if logged_in?
      # load privileges without an authorizable object
      @current_privileges = current_user.privileges.collect(&:name)
    else
      @current_privileges = []
    end
  end
  
  # def init_current_roles
  #   if logged_in?
  #     # load privileges without an authorizable object
  #     @current_roles = current_user.roles.collect(&:name)
  #   else
  #     @current_roles = []
  #   end
  # end
  
  def init_localities
    # country is required for all actions
    @country  = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => params[:controller], :action => 'error', :locality => 'country') and return
    end
    
    case params[:action]
    when 'country'
      case params[:controller]
      when 'places', 'search', 'zips'
        # find all states with locations
        @states = @country.states.with_locations
      when 'events'
        # find all states with events
        @states = @country.states.with_events
      end
      # track events
      track_where_ga_event(params[:controller], @country)
      return true
    else
      # find the specified state for all other cases
      @state  = @country.states.find_by_code(params[:state].to_s.upcase)
    end

    if @state.blank?
      redirect_to(:controller => params[:controller], :action => 'error', :locality => 'state') and return
    end
    
    case params[:action]
    when 'state'
      case params[:controller]
      when 'places'
        # find all state cities and zips with locations
        @cities = @state.cities.with_locations.order_by_name
        @zips   = @state.zips.with_locations
      when 'events'
        # find all state cities with events
        self.class.benchmark("Benchmarking #{@state.name} cities with events") do
          # find city events
          city_limit  = 10
          @facets     = Appointment.facets(:with => Search.attributes(@state), :facets => :city_id, :group_clause => "@count desc", :limit => city_limit)
          @cities     = Search.load_from_facets(@facets, City).sort_by { |o| o.name }
        end
      when 'search'
        # find all state cities with locations
        @cities = @state.cities.with_locations.order_by_name
      when 'zips'
        # find all state cities and zips with locations
        @zips   = @state.zips.with_locations.order_by_density
        @cities = @state.cities.with_locations.order_by_name
      end

      # track events
      track_where_ga_event(params[:controller], @state)
    when 'city', 'city_day'
      # find city, and all city zips and neighborhoods
      @city = @state.cities.find_by_name(params[:city].to_s.titleize)

      if @city.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'city') and return
      end

      self.class.benchmark("*** Benchmarking #{@city.name} neighborhoods using database", Logger::INFO, false) do
        @neighborhoods = @city.neighborhoods.with_locations.order_by_density(:limit => 100).sort_by { |o| o.name }
      end

      if @neighborhoods.blank?
        # find city zips only if there are no neighborhoods
        self.class.benchmark("*** Benchmarking #{@city.name} zips using database", Logger::INFO) do
          @zips = @city.zips
        end
      end

      # initialize city events count
      @events_count = @city.events_count

      # track events
      track_where_ga_event(params[:controller], @city)
    when 'neighborhood'
      # find city and neighborhood
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)
      @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?

      if @city and @neighborhood.blank?
        # neighborhoods can have non-letter characters; try resolving again
        @neighborhood = @city.neighborhoods.find_like(params[:neighborhood].gsub('-','%')).first
      end

      if @city.blank? or @neighborhood.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'city') and return if @city.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'neighborhood') and return if @neighborhood.blank?
      end

      # initialize city events count
      @events_count = @neighborhood.events_count

      # track events
      track_where_ga_event(params[:controller], @neighborhood)
    when 'zip'
      # find zip and all zip cities
      @zip = @state.zips.find_by_name(params[:zip].to_s)

      if @zip.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'zip') and return
      end

      self.class.benchmark("Benchmarking #{@zip.name} cities using database") do
        @cities = @zip.cities
        # use cities collection to use city with most locations as 'primary city' for this zip
        @city   = @zip.cities.sort_by { |o| -o.locations_count }.first
      end

      # initialize zip events count
      @events_count = @zip.events_count

      # track events
      track_where_ga_event(params[:controller], @zip)
    when 'index'
      # find city, zip and/or neighborhood
      # city or zip must be specified; if its a city, neighborhood is optional
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize) unless params[:city].blank?
      @zip            = @state.zips.find_by_name(params[:zip].to_s) unless params[:zip].blank?
      @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank? or params[:neighborhood].blank?

      if @city and @neighborhood.blank? and !params[:neighborhood].blank?
        # neighborhoods can have non-letter characters; try resolving again
        @neighborhood = @city.neighborhoods.find_like(params[:neighborhood].gsub('-','%')).first
      end

      # if its a city, check for lat/lng coordinates
      if @city and (!params[:lat].blank? and !params[:lng].blank?)
        @geo_origin = true
        @lat        = BigDecimal.from_url_param(params[:lat])
        @lng        = BigDecimal.from_url_param(params[:lng])
        @street     = params[:street].to_s.from_url_param.titleize
      end

      if @city.blank? and @zip.blank?
        # invalid search
        redirect_to(:controller => params[:controller], :action => 'error', :locality => @state) and return
      end

      # initialize geo events count
      if @neighborhood
        @events_count = @neighborhood.events_count
      elsif @city
        @events_count = @city.events_count
      elsif @zip
        @events_count = @zip.events_count
      end

      # track events
      if @neighborhood
        # track only the neighborhood event
        track_where_ga_event(params[:klass], [@neighborhood])
      else
        # track city or zip event
        track_where_ga_event(params[:klass], [@city, @zip].compact)
      end
    end
    
    return true
  end

  def init_weather
    @weather = nil

    if WEATHER_ENVS.include?(RAILS_ENV)
    case
    when @city
      if Weather.city?(@city)
        self.class.benchmark("*** Benchmarking #{@city.name.downcase} weather", APP_LOGGER_LEVEL, false) do
          # initialize city weather
          @weather = Rails.cache.fetch("weather:#{@state.code.downcase}:#{@city.name.to_url_param}", :expires_in => CacheExpire.weather) do
            Weather.get("#{@city.name},#{@state.name}", "#{@city.name} Weather")
          end
        end
      end
    when @zip
      if Weather.zip?(@zip)
        self.class.benchmark("*** Benchmarking #{@zip.name} weather", APP_LOGGER_LEVEL, false) do
          # initialize zip weather
          @weather = Rails.cache.fetch("weather:#{@state.code.downcase}:#{@zip.name}", :expires_in => CacheExpire.weather) do
            Weather.get("#{@zip.name}", "#{@zip.name} Weather")
          end
        end
      end
    end # case
    end # RAILS_ENV

    @weather
  end

  def normalize_page_number
    if params[:page] == '1'
      # redirect to url without page number
      redirect_to(:page => nil) and return
    end
  end
  
  def build_search_title(options={})
    tag       = options[:tag] || ''
    street    = options[:street] || ''
    query     = options[:query] || ''
    filter    = options[:filter] || ''
    klass     = options[:klass] || 'search'

    raise ArgumentError if tag.blank? and query.blank? and filter.blank?
    
    if options[:state] and options[:city] and options[:neighborhood]
      where = "#{options[:neighborhood].name}, #{options[:city].name}, #{options[:state].code}"
    elsif options[:state] and options[:city] and options[:street]
      where = "#{options[:street]}, #{options[:city].name}, #{options[:state].code}"
    elsif options[:state] and options[:city]
      where = "#{options[:city].name}, #{options[:state].code}"
    elsif options[:state] and options[:zip]
      where = "#{options[:state].code}, #{options[:zip].name}"
    else
      raise Exception, "invalid search"
    end

    # use 'tag', then 'query', then 'filter'
    if !tag.blank?
      subject = tag
    elsif !query.blank?
      subject = query
    elsif !filter.blank?
      subject = filter
    end
    
    # add specifics based on the klass
    case klass
    when 'locations', 'places'
      subject += " Places"
    when 'events' 
      subject += " Events"
    end

    # check for special 'anything' search
    if subject.to_s.downcase.match(/^anything/)
      # change subject to 'Events|Places Directory'
      case klass
      when 'locations', 'places', 'search'
        subject = "Places Directory"
      when 'events'
        subject = "Events Directory"
      end
    end

    # build title from subject and where
    title = "#{subject.titleize} near #{where}"

    title
  end 

  def build_place_title(place, location, options={})
    street  = options[:street]
    city    = options[:city]
    state   = options[:state]
    zip     = options[:zip]

    # start with place name
    tuple   = [place.name]

    if city.blank? and state.blank? and zip.blank?
      return tuple.join(" - ")
    end

    address = [street]
    # add street, city, state, zip
    if city and state and zip
      address.push("#{city.name} #{state.code}, #{zip.name}")
    elsif city and state
      address.push("#{city.name} #{state.code}")
    elsif city
      address.push("#{city.name}")
    end
    tuple.push(address.reject(&:blank?).join(", "))

    if location.phone_numbers_count > 0
      # add phone number
      tuple.push(number_to_phone(location.primary_phone_number.address, :delimiter => " "))
    end

    tuple.join(" - ")
  end

  protected

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end

  def force_full_site
    if mobile_device?
      request.format = :html
    end
  end

  helper_method :mobile_device?

  def prepare_for_mobile
    # set session param if there is a 'mobile' url param
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end

end
