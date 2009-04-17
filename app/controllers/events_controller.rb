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
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter

    # find popular city events
    @results  = EventfulFeed::Search.call(:location => @city.name, :sort_order => "popularity")
    @events   = @results['events'] ? @results['events']['event'] : []
    
    @total    = @results['total_items']
    @count    = @results['page_items']   # events on this page
    
    @title    = "#{@city.name} Events Directory"
  end
end