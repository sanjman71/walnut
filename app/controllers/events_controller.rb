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
    @categories = EventfulFeed::Category.all
    
    @title    = "#{@city.name} Events Directory"
  end
  
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @filter     = params[:filter]
    @category   = params[:category] ? EventfulFeed::Category.find_by_eventful_id(params[:category].underscore) : nil

    if @filter and @category
      # is this allowed?
    end
    
    # build events search conditions
    @conditions = {:location => @city.name, :date => 'Future', :page_size => 10}
    
    if @filter
      case @filter
      when 'popular'
        @conditions[:sort_order] = 'popularity'
        @title  = "#{@city.name} Popular Events"
      end
    end
    
    if @category
      @conditions[:category] = @category
      @title  = "#{@city.name} #{@category.name.singularize.titleize} Events"
    end
    
    # find city events
    @results    = EventfulFeed::Search.call(@conditions)
    @events     = @results['events'] ? @results['events']['event'] : []
    
    # sort events by date
    @events     = @events.sort_by { |e| e['start_time'] if e['start_time'] }
      
    @total      = @results['total_items']
    @count      = @results['page_items']   # events on this page
    @first_item = @results['first_item']
    @last_item  = @results['last_item']
    
    # find popular categories
    @categories = EventfulFeed::Category.find(:all, :limit => 5)
  end
  
end