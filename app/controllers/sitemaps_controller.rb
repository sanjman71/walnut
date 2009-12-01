class SitemapsController < ApplicationController
  caches_page :events
  caches_page :tags

  layout nil # turn off layouts
  
  # GET /sitemaps.events
  def events
    @protocol = self.request.protocol
    @host     = self.request.host
    
    respond_to do |format|
      format.xml
    end
  end

  # GET /sitemaps.tags.charlotte
  # GET /sitemaps.tags.chicago
  def tags
    @city     = City.find_by_name(params[:city].titleize)
    @state    = @city.state
    @country  = Country.us

    @protocol = self.request.protocol
    @host     = self.request.host

    # build tags collection from (cached) geo tag counts in the database, sort by name
    @tags     = @city.tags.uniq.sort_by{ |o| o.name }

    respond_to do |format|
      format.xml
    end
  end

end