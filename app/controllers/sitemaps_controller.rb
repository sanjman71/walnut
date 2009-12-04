class SitemapsController < ApplicationController
  caches_page :events
  caches_page :tags
  caches_page :locations

  layout nil # turn off layouts
  
  # max urls in a single sitemap (protocol allows 50000)
  @@urls_per_sitemap   = 5000

  # GET /sitemap.events.xml
  def events
    @protocol = self.request.protocol
    @host     = self.request.host
    
    respond_to do |format|
      format.xml
    end
  end

  # GET /sitemap.tags.charlotte.xml
  # GET /sitemap.tags.chicago.xml
  def tags
    @city     = City.find_by_name(params[:city].titleize)
    @state    = @city.state
    @country  = Country.us

    # build tags collection from (cached) geo tag counts in the database, sort by name
    @tags     = @city.tags.uniq.sort_by{ |o| o.name }

    @protocol = self.request.protocol
    @host     = self.request.host

    respond_to do |format|
      format.xml
    end
  end

  # GET /sitemap.locations.charlotte.1.xml
  # GET /sitemap.locations.chicago.1.xml
  def locations
    @index      = params[:index].to_i
    @city       = City.find_by_name(params[:city].titleize)
    @state      = @city.state
    @country    = Country.us

    # find city locations
    @offset     = (@index-1) * @@urls_per_sitemap
    @locations  = Location.with_city(@city).all(:offset => @offset, :limit => @@urls_per_sitemap, :select => "id", :include => :companies)
    
    @protocol   = self.request.protocol
    @host       = self.request.host

    respond_to do |format|
      format.xml
    end
  end

end