class HomeController < ApplicationController
  def index
    @country = Country.default

    # find a city to highlight
    @featured_city = find_featured_city
    
    # find featured city objects
    featured_limit = 5

    self.class.benchmark("Benchmarking #{@featured_city.name} featured set") do
      @featured_set = Rails.cache.fetch("#{@featured_city.name.parameterize}:featured_set", :expires_in => CacheExpire.locations) do
        ThinkingSphinx::Search.search(:with => Search.attributes(@featured_city), :classes => [Location], :page => 1, :per_page => featured_limit, :order => :popularity, :sort_mode => :desc)
      end
    end

    # find popular cities based on city density
    self.class.benchmark("Benchmarking popular cities using database") do
      city_limit      = 10
      city_density    = 25000
      @cities         = Rails.cache.fetch("popular_cities:#{city_limit}:#{city_density}", :expires_in => CacheExpire.localities) do
        City.with_locations.order_by_density.all(:limit => city_limit, :include => :state, :conditions => ['locations_count > ?', city_density])
      end
    end

    self.class.benchmark("Benchmarking popular city neighborhoods using database") do
      hood_limit      = 25
      # build hash mapping cities to their neighborhoods ranked by density
      @neighborhoods  = Rails.cache.fetch("popular_neighborhoods:#{hood_limit}", :expires_in => CacheExpire.localities) do
        @cities.inject(ActiveSupport::OrderedHash.new) do |hash, city|
          hash[city] = city.neighborhoods.with_locations.order_by_density.all(:limit => hood_limit, :include => :city)
          hash
        end
      end
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

  def find_featured_city
    # find a randomly selected featured city
    # city = City.order_by_density.all(:limit => 1, :include => :state, :order => 'rand()', :conditions => ["locations_count > 25000"]).first
    # default to city with most locations
    city = City.find(:first, :order => "locations_count DESC") if city.blank?
    city
  end

end