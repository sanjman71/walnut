class SitemapsController < ApplicationController
  caches_page :events
  caches_page :tags
  caches_page :locations
  caches_page :index_locations

  layout nil # turn off layouts
  
  # max urls in a single sitemap (protocol allows 50000)
  @@urls_per_sitemap  = 5000
  
  # max entries in an index file
  @@entries_per_index = 1000

  # GET /sitemap.events.xml
  def events
    @protocol = self.request.protocol
    @host     = self.request.host
    
    respond_to do |format|
      format.xml
    end
  end

  # GET /sitemap.tags.nc.charlotte.xml
  # GET /sitemap.tags.il.chicago.xml
  def tags
    @state    = State.find_by_code(params[:state])
    @city     = @state.cities.find_by_name(params[:city].titleize)
    @country  = Country.us

    # build tags collection from (cached) geo tag counts in the database, sort by name
    @tags     = @city.tags.uniq.sort_by{ |o| o.name }

    @protocol = self.request.protocol
    @host     = self.request.host

    respond_to do |format|
      format.xml
    end
  end

  # GET /sitemap.index.locations.il.chicago.xml
  # GET /sitemap.index.locations.cities.medium.xml
  def index_locations
    @country    = Country.us
    @city_size  = params[:city_size]
    
    case @city_size
    when 'medium', 'small', 'tiny'
      # range is number of locations, which is based on the city size
      case @city_size
      when 'medium'
        conditions = ["cities.locations_count < 25000 AND cities.locations_count >= 5000"]
      when 'small'
        conditions = ["cities.locations_count < 5000 AND cities.locations_count >= 1000"]
      when 'tiny'
        conditions = ["cities.locations_count < 1000"]
      end
      @count      = Location.count(:offset => @offset, :limit => @@urls_per_sitemap, :joins => :city, :conditions => conditions)
      @iend       = @count/@@urls_per_sitemap + ((@count % @@urls_per_sitemap) == 0 ? 0 : 1)
      @range      = Range.new(1, [@iend, @@entries_per_index].min)
      # build sitemap root to this range of cities
      @root       = "/sitemap.locations.cities.#{@city_size}."
    else
      # use specified state, city
      @state      = @country.states.find_by_code(params[:state])
      @city       = @state.cities.find_by_name(params[:city].titleize)
      # figure out how many sitemaps are needed for this city based on locations count
      @iend       = @city.locations_count/@@urls_per_sitemap + ((@city.locations_count % @@urls_per_sitemap) == 0 ? 0 : 1)
      @range      = Range.new(1, [@iend, @@entries_per_index].min)
      # build sitemap root to this city
      @root       = "/sitemap.locations.#{@state.code.downcase}.#{@city.name.to_url_param}."
    end


    @protocol   = self.request.protocol
    @host       = self.request.host

    respond_to do |format|
      format.xml
    end
  end

  # GET /sitemap.locations.nc.charlotte.1.xml
  # GET /sitemap.locations.il.chicago.1.xml
  # GET /sitemap.locations.cities.tiny.1.xml
  # GET /sitemap.locations.cities.small.1.xml
  # GET /sitemap.locations.cities.medium.1.xml
  def locations
    @index      = params[:index].to_i
    @offset     = (@index-1) * @@urls_per_sitemap

    @country    = Country.us
    @city_size  = params[:city_size]

    case @city_size
    when 'medium' # ~ 187K locations
      conditions  = ["cities.locations_count < 25000 AND cities.locations_count >= 5000"]
      @locations  = Location.all(:offset => @offset, :limit => @@urls_per_sitemap, :joins => :city, :conditions => conditions)
    when 'small' # ~ 773K locations
      conditions  = ["cities.locations_count < 5000 AND cities.locations_count >= 1000"]
      @locations  = Location.all(:offset => @offset, :limit => @@urls_per_sitemap, :joins => :city, :conditions => conditions)
    when 'tiny' # ~ 440K locations
      conditions  = ["cities.locations_count < 1000"]
      @locations  = Location.all(:offset => @offset, :limit => @@urls_per_sitemap, :joins => :city, :conditions => conditions)
    else
      # use specified state, city
      @state      = @country.states.find_by_code(params[:state])
      @city       = @state.cities.find_by_name(params[:city].titleize)
      # find city locations
      @locations  = Location.with_city(@city).all(:offset => @offset, :limit => @@urls_per_sitemap, :select => "id", :include => :companies)
    end

    # we must have at least 1 location
    if @locations.size == 0
      # redirect to a smaller index
      redirect_to url_for(params.merge(:index => @index-1)) and return
    end

    @protocol   = self.request.protocol
    @host       = self.request.host

    respond_to do |format|
      format.xml
    end
  end

end