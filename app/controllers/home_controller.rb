class HomeController < ApplicationController
  def index
    @country        = Country.default
    
    # find popular cities and neighborhoods
    
    self.class.benchmark("Benchmarking popular cities") do
      city_limit      = 10
      @facets         = Location.facets(:with => Search.with(@country), :facets => "city_id", :limit => city_limit, :max_matches => city_limit)
      @cities         = Search.load_from_facets(@facets, City)
    end
    
    self.class.benchmark("Benchmarking popular neighborhoods") do
      hood_limit      = 10
      @facets         = Location.facets(:with => Search.with(@country), :facets => "neighborhood_ids", :limit => hood_limit, :max_matches => hood_limit)
      @neighborhoods  = Search.load_from_facets(@facets, Neighborhood)
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