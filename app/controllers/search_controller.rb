class SearchController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:index]

  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @what           = params[:what].to_s.from_url_param
    
    # handle special case of 'something' to find a random what
    @what           = Tag.all(:order => 'rand()', :limit => 1).first.name if @what == 'something'

    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @what)
    @with           = @search.field(:locality_hash)

    @objects        = ThinkingSphinx::Search.search(@what, :classes => [Event, Location], :with => @with, :page => params[:page], :per_page => 20)

    # raise Exception, "found #{@objects.size} results"
  end
  
end