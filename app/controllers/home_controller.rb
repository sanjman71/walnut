class HomeController < ApplicationController
  def index
    @country = Country.default

    # find a city to highlight
    @city = City.order_by_density.all(:limit => 1, :include => :state).first
    
    # find city events
    @with = Search.with(@city)
    # @with.update(:popularity => 1..1000)
    
    self.class.benchmark("Benchmarking #{@city.name} popular events") do
      Rails.cache.fetch("#{@city.name}:popular:events") do
        event_limit = 6
        @events     = Event.search(@query, :with => @with, :include => :event_venue, :page => 1, :per_page => event_limit, :order => :popularity, :sort_mode => :desc)
      end
    end

    # find popular cities and neighborhoods
    
    self.class.benchmark("Benchmarking popular cities using database") do
      city_limit      = 10
      @cities         = City.with_locations.order_by_density.all(:limit => city_limit, :include => :state)
    end

    self.class.benchmark("Benchmarking popular neighborhoods using database") do
      hood_limit      = 10
      @neighborhoods  = Neighborhood.with_locations.order_by_density.all(:limit => hood_limit, :include => :city)
    end
    
    # track event
    track_home_ga_event(params[:controller], "Index")

    respond_to do |format|
      format.html
    end
  end

  # Handle all unauthorized access redirects
  def unauthorized
    respond_to do |format|
      format.html
    end
  end

end