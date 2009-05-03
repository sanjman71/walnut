class EventsController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:country, :state, :city, :neighborhood, :zip, :index]

  def country
    # @country initialized in before filter
    
    # find city by events by country
    @city_facet = "city_id"
    @with       = Search.with(@country)
    @facets     = Event.facets(:facets => @city_facet)
    @cities     = Search.load_from_facets(@facets, City).sort_by { |o| o.name }
    
    @title      = "#{@country.name} Events Directory"
    @h1         = @title
  end
      
  def state
    # @country, @state  all initialized in before filter

    # find events by city in this state
    @city_facet = "city_id"
    @with       = Search.with(@state)
    @facets     = Event.facets(:facets => @city_facet)
    @cities     = Search.load_from_facets(@facets, City).sort_by { |o| o.name }

    @title      = "#{@state.name} Events Directory"
    @h1         = @title
  end

  def city
    # @country, @state, @city all initialized in before filter

    # find faceted event categories in the specified city
    # @category_facet = "event_category_ids"
    # @facets         = Event.facets(:with => {:city_id => 1}, :facets => @category_facet)
    # @categories     = Search.load_from_facets(@facets, EventCategory).sort_by { |o| o.name }

    # generate tag counts using facets
    options         = {:with => Search.with(@city)}.update(Search.tag_group_options(150))
    @facets         = Event.facets(options)
    @tags           = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }

    @title          = "#{@city.name} Events Directory"
    @h1             = @title
  end
  
  def search
    redirect_to(url_for(:action => 'index', :q => params[:q].to_s.parameterize, :category => nil, :sort => nil)) and return
  end
  
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @tag        = params[:tag].to_s.from_url_param
    @what       = params[:what].to_s.from_url_param
    
    @category   = params[:category] ? EventCategory.find_by_source_id(params[:category].underscore) : nil
    @sort       = params[:sort]
    
    if @sort and @category
      # is this allowed?
    end
    
    if @tag.blank? and @what.blank? and @sort.blank? and @category.blank?
      # redirect to default sort
      redirect_to(url_for(:sort => 'popularity')) and return
    end
    
    # if @sort
    #   case @sort
    #   when 'popular'
    #     # @conditions[:sort_order] = 'popularity'
    #     @title  = "#{@city.name} Popular Events"
    #   end
    # end
    # 
    # if @category
    #   @title  = "#{@city.name} #{@category.name.singularize.titleize} Events"
    # end
        
    # find city events
    @search     = Search.parse([@country, @state, @city, @neighborhood, @zip], @tag.blank? ? @what : @tag)
    @query      = @search.query
    @with       = Search.with(@city)
    @with.update(:event_category_ids => @category.id) if @category
    @events     = Event.search(@query, :with => @with, :include => :event_venue, :page => params[:page], :per_page => 20)
        
    # find popular categories
    # @categories = EventCategory.popular.order_by_name - [@category]
    
    # find popular tags
    options     = {:with => @with}.update(Search.tag_group_options(10))
    @facets     = Event.facets(options)
    @tags       = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }.delete_if { |t| t.name == @tag }
    
    # build search title based on [what, filter] and city, neighborhood, zip search
    @title  = build_search_title(:what => @what, :tag => @tag, :category => @category ? @category.name : '', :filter => @filter, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1     = @title

    # track what event
    track_what_ga_event(params[:controller], :tag => @tag, :what => @what)
  end
  
end