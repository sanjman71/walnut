class HomeController < ApplicationController
  def index
    @country        = Country.default
    
    # find popular cities and neighborhoods
    @facets         = Location.facets(:with => {:country_id => @country.id}, :facets => ["city_id", "neighborhood_ids"])
    @cities         = Search.load_from_facets(@facets, City)
    @neighborhoods  = Search.load_from_facets(@facets, Neighborhood)
    
    # @cities         = City.with_locations.order_by_density.all(:limit => 30)
    # @neighborhoods  = Neighborhood.with_locations.order_by_density.all(:limit => 10, :include => :city)

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