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

    self.class.benchmark("Benchmarking #{@city.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@state.code.downcase}:#{@city.name.to_url_param}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud from (cached) geo tag counts in the database
        tags = @city.tags
        # return sorted, unique tags collection
        tags.sort_by { |o| o.name }.uniq
      end
    end

    respond_to do |format|
      format.xml
    end
  end

end