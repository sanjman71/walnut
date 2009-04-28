# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # Make the following methods available to all helpers
  helper_method :has_privilege?, :recommended?, :recommended_by_me?, :ga_events
  
  # AuthenticatedSystem is used by restful_authentication
  include AuthenticatedSystem
  
  include RecommendationsHelper
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '7c342efc7bc88b372c5913ebad934c5e'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password
  
  # Load and cache all user privileges and roles on each call so we don't have to keep checking the database
  before_filter :init_current_privileges, :init_current_roles
  
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
  
  def init_current_roles
    if logged_in?
      # load privileges without an authorizable object
      @current_roles = current_user.roles.collect(&:name)
    else
      @current_roles = []
    end
  end
  
  def init_localities
    # country is required for all actions
    @country  = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => params[:controller], :action => 'error', :locality => 'country') and return
    end
    
    case params[:action]
    when 'country'
      case params[:controller]
      when 'places'
        # find all states with locations
        @states = @country.states.with_locations
      when 'events'
        # find all states with events
        @states = @country.states.with_events
      end
      # track events
      init_ga_events(params[:controller], @country)
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
        @cities = @state.cities.with_locations
        @zips   = @state.zips.with_locations
      when 'events'
        # find all state cities with events
        @cities = @state.cities.with_events
      end

      # track events
      init_ga_events(params[:controller], @state)
    when 'city'
      # find city, and all city zips and neighborhoods
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)

      if @city.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'city') and return
      end

      @zips           = @city.zips
      @neighborhoods  = @city.neighborhoods

      # track events
      init_ga_events(params[:controller], @city)
    when 'neighborhood'
      # find city and neighborhood
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)
      @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?

      if @city.blank? or @neighborhood.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'city') and return if @city.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'neighborhood') and return if @neighborhood.blank?
      end

      # track events
      init_ga_events(params[:controller], @neighborhood)
    when 'zip'
      # find zip and all zip cities
      @zip      = @state.zips.find_by_name(params[:zip].to_s)

      if @zip.blank?
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'zip') and return
      end

      @cities   = @zip.cities

      # track events
      init_ga_events(params[:controller], @zip)
    when 'index'
      # find city, zip and/or neighborhood
      # city or zip must be specified; if its a city, neighborhood is optional
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize) unless params[:city].blank?
      @zip            = @state.zips.find_by_name(params[:zip].to_s) unless params[:zip].blank?
      @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank? or params[:neighborhood].blank?
      
      if @city.blank? and @zip.blank?
        # invalid search
        redirect_to(:controller => params[:controller], :action => 'error', :locality => 'unknown') and return
      end

      # track events
      if @neighborhood
        # track only the neighborhood event
        init_ga_events(params[:controller], [@neighborhood])
      else
        # track city or zip event
        init_ga_events(params[:controller], [@city, @zip].compact)
      end
    end
    
    return true
  end
  
  def normalize_page_number
    if params[:page] == '1'
      # redirect to url without page number
      redirect_to(:page => nil) and return
    end
  end
  
  def init_ga_events(category, localities)
    @ga_events ||= []
    
    case category
    when 'events', 'places'
      Array(localities).compact.each do |locality|
        @ga_events.push("pageTracker._trackEvent('#{category.titleize}', '#{locality.class.to_s}', '#{locality.name}');")
      end
    else
    end
  end
  
end
