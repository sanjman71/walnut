class HomeController < ApplicationController
  def index
    @country = Country.default

    # find a city to highlight
    @featured_city = find_featured_city
    
    # find featured city events
    @featured_with = Search.with(@featured_city)
    featured_limit = 5

    # self.class.benchmark("Benchmarking #{@featured_city.name} popular events") do
    @featured_events = Rails.cache.fetch("#{@featured_city.name.parameterize}:popular:events") do
      Event.search(:with => @featured_with, :include => :event_venue, :page => 1, :per_page => featured_limit, :order => :popularity, :sort_mode => :desc)
    end
    # end

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

  protected

  # find a randomly selected featured city
  def find_featured_city
    City.order_by_density.all(:limit => 1, :include => :state, :order => 'rand()', :conditions => ["locations_count > 25000"]).first
  end

end