class SearchController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:city, :index]

  def city
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter
    
    # generate location tag counts
    options       = {:with => Search.with(@city)}.update(Search.tag_group_options(150))
    @facets       = Location.facets(options)
    @tags         = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    
    # find city events
    @facets       = Event.facets(:with => Search.with(@city), :facets => "city_id")
    @events_count = @facets[:city_id][@city.id]
    
    @title        = "#{@city.name}, #{@state.name} Yellow Pages"
    @h1           = "Browse #{@city.name}, #{@state.name}"
  end

  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @tag            = params[:tag].to_s.from_url_param
    @what           = params[:what].to_s.from_url_param
    
    # handle special case of 'something' to find a random what
    @what           = Tag.all(:order => 'rand()', :limit => 1).first.name if @what == 'something'

    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @tag.blank? ? @what : @tag)
    @query          = @search.query
    @with           = @search.field(:locality_hash)

    @objects        = ThinkingSphinx::Search.search(@query, :classes => [Event, Location], :with => @with, :page => params[:page], :per_page => 20,
                                                    :order => :popularity, :sort_mode => :desc)

    # build search title based on what, city, neighborhood, zip search
    @title          = build_search_title(:tag => @tag, :what => @what, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title

    # track what event
    track_what_ga_event(params[:controller], :tag => @tag, :what => @what)
  end
  
  def resolve
    # resolve where parameter
    @locality = Locality.resolve(params[:where].to_s)
    @what     = params[:what].to_s.parameterize
    
    if @locality.blank?
      redirect_to(:action => 'error', :locality => 'unknown') and return
    end
    
    case @locality.class.to_s
    when 'City'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :city => @locality, :what => @what) and return
    when 'Zip'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :zip => @locality, :what => @what) and return
    when 'Neighborhood'
      @city     = @locality.city
      @state    = @city.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :city => @city, :neighborhood => @locality, :what => @what) and return
    when 'State'
      raise Exception, "search by state not supported"
    else
      redirect_to(root_path)
    end
  end
  
  def error
    @title  = "Search Error"
  end
  
end