class PlacesController < ApplicationController
  before_filter   :init_areas, :only => [:country, :state, :city, :neighborhood, :zip]
  layout "home"
  
  def country
    # @country, @states initialized in before filter
    @title  = "#{@country.name} Yellow Pages"
  end
      
  def state
    # @country, @state, @cities, @zips all initialized in before filter
    @title  = "#{@state.name} Yellow Pages"
  end
  
  def city
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter
    @tags   = Address.place_tag_counts.sort_by(&:name)
    @title  = "#{@city.name}, #{@state.name} Yellow Pages"
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter
    @tags   = Address.place_tag_counts.sort_by(&:name)
    @title  = "#{@neighborhood.name}, #{@city.name}, #{@state.name} Yellow Pages"
  end
  
  def zip
    # @country, @state, @zip and @cities all initialized in before filter
    @tags   = Address.place_tag_counts.sort_by(&:name)
    @title  = "#{@state.name} #{@zip.name} Yellow Pages"
  end
  
  def search
    # resolve where parameter
    @area   = Area.resolve(params[:where].to_s)
    @tag    = params[:what].to_s
    
    if @area.blank?
      redirect_to(:action => 'error', :area => 'area') and return
    end
    
    case @area.class.to_s
    when 'City'
      @state    = @area.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :city => @area, :tag => @tag) and return
    when 'Zip'
      @state    = @area.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :zip => @area, :tag => @tag) and return
    when 'Neighborhood'
      @city     = @area.city
      @state    = @city.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :city => @city, :neighborhood => @area, :tag => @tag) and return
    when 'State'
      raise Exception, "not allowed to search by state"
    end
    
  end
  
  def index
    @country        = Country.find_by_code(params[:country].to_s.upcase)
    @state          = State.find_by_code(params[:state].to_s.upcase)
    @city           = @state.cities.find_by_name(params[:city].to_s.titleize) unless @state.blank?
    @zip            = @state.zips.find_by_name(params[:zip].to_s) unless @state.blank?
    @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?
    @tag            = params[:tag]
    
    # build sphinx query
    @query          = [@country, @state, @city, @neighborhood, @zip, @tag].compact.collect { |o| o.is_a?(String) ? o : o.name }.join(" ")

    # build search title based on city, neighborhood, zip search
    @title          = build_search_title(:tag => @tag, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title
    
    # find addresses matching query
    @addresses      = Address.search(@query).paginate(:page => params[:page])
  end
  
  def show
    @address  = Address.find(params[:id])
    @place    = @address.place unless @address.blank?
    
    @title    = "#{@place.name}"
    @h1       = @title
  end
  
  def error
    @error_text = "We are sorry, but we couldn't find the #{params[:area]} you were looking for."
  end
  
  protected
  
  def build_search_title(options={})
    tag = options[:tag] || ''
    
    if options[:state] and options[:city] and options[:neighborhood]
      where = "#{options[:neighborhood].name}, #{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:city]
      where = "#{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:zip]
      where = "#{options[:state].name}, #{options[:zip].name}"
    else
      raise Exception, "invalid search"
    end
    
    "#{tag.titleize} in #{where}"
  end
  
  def init_areas
    # country is required for all actions
    @country  = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => 'places', :action => 'error', :area => 'country') and return
    end
    
    case params[:action]
    when 'country'
      # find all states
      @states = @country.states
      return true
    else
      # find the specified state for all other cases
      @state  = State.find_by_code(params[:state].to_s.upcase)
    end

    if @state.blank?
      redirect_to(:controller => 'places', :action => 'error', :area => 'state') and return
    end
    
    case params[:action]
    when 'state'
      # find all state cities and zips
      @cities = @state.cities
      @zips   = @state.zips
    when 'city'
      # find city, and all its zips and neighborhoods
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)
      @zips           = @city.zips unless @city.blank?
      @neighborhoods  = @city.neighborhoods unless @city.blank?
      
      if @city.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'city') and return
      end
    when 'neighborhood'
      # find city and neighborhood
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)
      @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?

      if @city.blank? or @neighborhood.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'city') and return if @city.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'neighborhood') and return if @neighborhood.blank?
      end
    when 'zip'
      # find zip and all its cities
      @zip      = @state.zips.find_by_name(params[:zip].to_s)
      @cities   = @zip.cities unless @zip.blank?

      if @zip.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'zip') and return
      end
    end
    
    return true
  end
  
end
