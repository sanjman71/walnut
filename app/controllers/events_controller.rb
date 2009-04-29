class EventsController < ApplicationController
  before_filter   :init_localities, :only => [:country, :state, :city, :neighborhood, :zip, :index]

  def country
    # @country initialized in before filter
    
    # find faceted event count by city
    @city_facet = "city_id"
    @facets     = Event.facets(:facets => @city_facet)
    @city_ids   = @facets[@city_facet.to_sym]
    @cities     = City.find(@city_ids.keys, :order => "name", :include => :state)
    
    @title  = "#{@country.name} Events Directory"
  end
      
  def state
    # @country, @state  all initialized in before filter

    @title  = "#{@state.name} Events Directory"
  end

  def city
    # @country, @state, @city all initialized in before filter

    # find faceted event categories in the specified city
    @category_facet = "event_category_ids"
    @facets         = Event.facets(:with => {:city_id => 1}, :facets => @category_facet)
    @categories     = Search.load_from_facets(@facets, EventCategory).sort_by { |o| o.name }

    # generate tag counts using facets
    options         = {:with => Search.with(@city)}.update(Search.tag_count_options(150))
    @facets         = Event.facets(options)
    @tags           = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }

    @title          = "#{@city.name} Events Directory"
  end
  
  def search
    redirect_to(url_for(:action => 'index', :q => params[:q].to_s.parameterize, :category => nil, :sort => nil)) and return
  end
  
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @sort       = params[:sort]
    @category   = params[:category] ? EventCategory.find_by_source_id(params[:category].underscore) : nil
    @q          = params[:q] ? params[:q].from_url_param.titleize : nil
    
    if @sort and @category
      # is this allowed?
    end
    
    if @sort.blank? and @category.blank? and @q.blank?
      # redirect to default sort
      redirect_to(url_for(:sort => 'popularity')) and return
    end
    
    # build events search conditions
    @conditions = {:location => @city.name, :date => 'Future', :page_size => 10, :sort_order => 'popularity'}
    
    if @sort
      case @sort
      when 'popular'
        # @conditions[:sort_order] = 'popularity'
        @title  = "#{@city.name} Popular Events"
      end
    end
    
    if @category
      @conditions[:category] = @category.source_id
      @title  = "#{@city.name} #{@category.name.singularize.titleize} Events"
    end
    
    if @q
      @conditions[:q] = @q
      @title  = "#{@city.name} Events matching '#{@q}'"
    end
    
    # find city events
    @with     = {:city_id => @city.id}
    @with.update(:event_category_ids => @category.id) if @category
    @events   = Event.search(:with => @with, :include => :event_venue, :page => 1, :per_page => 20)
    
    # find city events, sort by date
    # @results    = EventStream::Search.call(@conditions)
    # @events     = @results['events'] ? @results['events']['event'] : []
    # @events     = @events.sort_by { |e| e['start_time'] if e['start_time'] }
    #   
    # @total      = @results['total_items']
    # @count      = @results['page_items']   # the number of events on this page
    # @first_item = @results['first_item']   # the first item number on this page, e.g. 11
    # @last_item  = @results['last_item']    # the last item number on this page, e.g. 20
    
    # find popular categories
    @categories = EventCategory.popular.order_by_name - [@category]
  end
  
end