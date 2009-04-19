class EventsController < ApplicationController
  before_filter   :init_localities, :only => [:country, :state, :city, :neighborhood, :zip, :index]

  def country
    # @country initialized in before filter
    
    @title  = "#{@country.name} Events Directory"
  end
      
  def state
    # @country, @state  all initialized in before filter
    
    @title  = "#{@state.name} Events Directory"
  end

  def city
    # @country, @state, @city all initialized in before filter

    # find all categories
    @categories = EventfulFeed::Category.order_by_name
    
    @title    = "#{@city.name} Events Directory"
  end
  
  def search
    redirect_to(url_for(:action => 'index', :q => params[:q].to_s.parameterize, :category => nil, :sort => nil)) and return
  end
  
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @sort       = params[:sort]
    @category   = params[:category] ? EventfulFeed::Category.find_by_eventful_id(params[:category].underscore) : nil
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
      @conditions[:category] = @category.eventful_id
      @title  = "#{@city.name} #{@category.name.singularize.titleize} Events"
    end
    
    if @q
      @conditions[:q] = @q
      @title  = "#{@city.name} Events matching '#{@q}'"
    end
    
    # find city events
    @results    = EventfulFeed::Search.call(@conditions)
    @events     = @results['events'] ? @results['events']['event'] : []
    
    # sort events by date
    @events     = @events.sort_by { |e| e['start_time'] if e['start_time'] }
      
    @total      = @results['total_items']
    @count      = @results['page_items']   # the number of events on this page
    @first_item = @results['first_item']   # the first item number on this page, e.g. 11
    @last_item  = @results['last_item']    # the last item number on this page, e.g. 20
    
    # find popular categories
    @categories = EventfulFeed::Category.popular.order_by_name - [@category]
  end
  
end