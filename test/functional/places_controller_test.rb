require 'test/test_helper'
require 'test/factories'

class PlacesControllerTest < ActionController::TestCase
  
  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
  end
  
  # country route
  should_route :get, '/places/us', :controller => 'places', :action => 'country', :country => 'us'
  
  # state route
  should_route :get, '/places/us/il',
               :controller => 'places', :action => 'state', :country => 'us', :state => 'il'
  # state tag route
  should_route :get, '/places/us/il/anywhere/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'anywhere', :what => 'food'

  # city route
  should_route :get, '/places/us/il/chicago', :controller => 'places', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  # city tag routes
  should_route :get, '/places/us/il/chicago/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :what => 'food'
  should_route :get, '/places/us/il/chicago/tag/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
  # hyphenated city tag route
  should_route :get, '/places/us/ny/new-york/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'ny', :city => 'new-york', :what => 'food'

  # neighborhood route
  should_route :get, '/places/us/il/chicago/n/river-north', 
               :controller => 'places', :action => 'neighborhood', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north'

  # neighborhood tag routes
  should_route :get, '/places/us/il/chicago/n/river-north/soccer',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', :what => 'soccer'
  should_route :get, '/places/us/il/chicago/n/river-north/tag/soccer', 
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', :tag => 'soccer'
  
  # zip route
  should_route :get, '/places/us/il/60610', 
               :controller => 'places', :action => 'zip', :country => 'us', :state => 'il', :zip => '60610'
  # zip tag routes
  should_route :get, '/places/us/il/60610/food', 
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :what => 'food'
  should_route :get, '/places/us/il/60610/tag/food', 
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food'
  
  # show route
  should_route :get, '/places/1', :controller => 'places', :action => 'show', :id => 1
  
  # city recommended route
  should_route :get, '/places/us/il/chicago/recommended',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :filter => 'recommended' 
  
  # error route
  should_route :get, '/places/error/country', :controller => 'places', :action => 'error', :locality => 'country'
  should_route :get, '/places/error/unknown', :controller => 'places', :action => 'error', :locality => 'unknown'
  
  context "search city" do
    context "with no locations" do
      setup do
        # ThinkingSphinx::Collection takes 4 arguments: page, per_page, entries, total_entries
        Location.stubs(:search).returns(ThinkingSphinx::Collection.new(1, 1, 0, 0))
        get :index, :country => 'us', :state => 'il', :city => 'chicago', :what => 'food'
      end
    
      should_respond_with :success
      should_render_template 'places/index.html.haml'
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to :what, :search, :title
      should_assign_to(:query) { "food" }
      should_assign_to(:title) { "Food Places near Chicago, Illinois" }
    end
  end
end
