require 'test/test_helper'
require 'test/factories'

class SearchControllerTest < ActionController::TestCase

  # search resolve route
  should_route :post, '/search/resolve', :controller => 'search', :action => 'resolve'
  
  # state route
  should_route :get, '/search/us/il', :controller => 'search', :action => 'state', :country => 'us', :state => 'il'
  
  # city route
  should_route :get, '/search/us/il/chicago', :controller => 'search', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  
  # city search tag/what routes
  should_route :get, '/search/us/il/chicago/q/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :query => 'food', :klass => 'search'
  should_route :get, '/search/us/il/chicago/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food', :klass => 'search'
  should_route :get, '/locations/us/il/chicago/q/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :query => 'food', :klass => 'locations'
  should_route :get, '/locations/us/il/chicago/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food', :klass => 'locations'
  should_route :get, '/events/us/il/chicago/q/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :query => 'food', :klass => 'events'
  should_route :get, '/events/us/il/chicago/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food', :klass => 'events'

  # neighborhood search tag/waht routes
  should_route :get, '/search/us/il/chicago/n/river-north/q/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :query => 'soccer', :klass => 'search'
  should_route :get, '/search/us/il/chicago/n/river-north/tag/soccer', 
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :tag => 'soccer', :klass => 'search'
  should_route :get, '/locations/us/il/chicago/n/river-north/q/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :query => 'soccer', :klass => 'locations'
  should_route :get, '/locations/us/il/chicago/n/river-north/tag/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :tag => 'soccer', :klass => 'locations'
  should_route :get, '/events/us/il/chicago/n/river-north/q/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :query => 'soccer', :klass => 'events'
  should_route :get, '/events/us/il/chicago/n/river-north/tag/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :tag => 'soccer', :klass => 'events'

  # zip search tag/what routes
  should_route :get, '/search/us/il/60610/q/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :query => 'food', :klass => 'search'
  should_route :get, '/search/us/il/60610/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food', :klass => 'search'
  should_route :get, '/locations/us/il/60610/q/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :query => 'food', :klass => 'locations'
  should_route :get, '/locations/us/il/60610/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food', :klass => 'locations'
  should_route :get, '/events/us/il/60610/q/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :query => 'food', :klass => 'events'
  should_route :get, '/events/us/il/60610/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food', :klass => 'events'


  # error route
  should_route :get, '/search/error/country', :controller => 'search', :action => 'error', :locality => 'country'
  should_route :get, '/search/error/unknown', :controller => 'search', :action => 'error', :locality => 'unknown'

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
  end
  
  context "search city" do
    context "with no locations" do
      setup do
        # ThinkingSphinx::Collection takes 4 arguments: page, per_page, entries, total_entries
        ThinkingSphinx::Search.stubs(:search).returns(ThinkingSphinx::Collection.new(1, 1, 0, 0))
        get :index, :klass => 'search', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
      end
    
      should_respond_with :success
      should_render_template 'search/index.html.haml'
      should_assign_to(:klasses) { [Event, Location] }
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to :query, :tag
      should_assign_to(:query_or) { "food" }
      should_assign_to(:query_and) { "food" }
      should_assign_to(:query_raw) { "food" }
      should_not_assign_to(:fields)
      should_assign_to(:attributes) { Hash[:city_id => @chicago.id, :state_id => @il.id, :country_id => @us.id] }
      should_assign_to(:title) { "Food near Chicago, Illinois" }
    end
  end

end