class HomeController < ApplicationController
  def index
    @country        = Country.default
    
    # find popular cities and neighborhoods
    options         = Search.with(@country).update(Search.city_group_options(10))
    @facets         = Location.facets(options)
    @cities         = Search.load_from_facets(@facets, City)
    
    options         = Search.with(@country).update(Search.neighborhood_group_options(10))
    @facets         = Location.facets(options)
    @neighborhoods  = Search.load_from_facets(@facets, Neighborhood)
    
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