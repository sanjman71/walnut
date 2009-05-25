class HomeController < ApplicationController
  def index
    @country = Country.default

    # find a city to highlight
    @featured_city = find_featured_city
    
    # find featured city events
    featured_limit = 5

    # self.class.benchmark("Benchmarking #{@featured_city.name} popular events") do
    #   @featured_events = Rails.cache.fetch("#{@featured_city.name.parameterize}:featured_events", :expires_in => CacheExpire.events) do
    #     Event.search(:with => Search.attributes(@featured_city), :include => :event_venue, :page => 1, :per_page => featured_limit, :order => :popularity, :sort_mode => :desc)
    #   end
    # end

    self.class.benchmark("Benchmarking #{@featured_city.name} featured set") do
      @featured_set = Rails.cache.fetch("#{@featured_city.name.parameterize}:featured_set", :expires_in => CacheExpire.locations) do
        ThinkingSphinx::Search.search(:with => Search.attributes(@featured_city), :classes => [Location], :page => 1, :per_page => featured_limit, :order => :popularity, :sort_mode => :desc)
      end
    end

    # find popular cities and neighborhoods
    
    self.class.benchmark("Benchmarking popular cities using database") do
      city_limit      = 10
      city_density    = 10000
      @cities         = City.with_locations.order_by_density.all(:limit => city_limit, :include => :state, :conditions => ['locations_count > ?', city_density])
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