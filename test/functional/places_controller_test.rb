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
  # country, tag route - no longer valid
  # should_route :get, '/places/us/food', :controller => 'places', :action => 'index', :country => 'us', :tag => 'food'
  
  # state route
  should_route :get, '/places/us/il',
               :controller => 'places', :action => 'state', :country => 'us', :state => 'il'
  # state tag route
  should_route :get, '/places/us/il/anywhere/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'anywhere', :tag => 'food'

  # city route
  should_route :get, '/places/us/il/chicago', :controller => 'places', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  # city tag route
  should_route :get, '/places/us/il/chicago/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
  # hyphenated city tag route
  should_route :get, '/places/us/ny/new-york/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'ny', :city => 'new-york', :tag => 'food'

  # neighborhood route
  should_route :get, '/places/us/il/chicago/n/river-north', 
               :controller => 'places', :action => 'neighborhood', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north'

  # neighborhood tag route
  should_route :get, '/places/us/il/chicago/n/river-north/soccer', 
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', :tag => 'soccer'
  
  # zip route
  should_route :get, '/places/us/il/60610', 
               :controller => 'places', :action => 'zip', :country => 'us', :state => 'il', :zip => '60610'
  # zip tag route
  should_route :get, '/places/us/il/60610/food', 
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food'
  
  # show route
  should_route :get, 'places/1', :controller => 'places', :action => 'show', :id => 1
  
  # error route
  should_route :get, '/places/error/country', :controller => 'places', :action => 'error', :area => 'country'
  
  context "search city" do
    context "with no locations" do
      setup do
        Location.stubs(:search).returns([])
        get :index, :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
      end
    
      should_respond_with :success
      should_render_template 'places/index.html.haml'
      should_assign_to :country, :equals => "@us"
      should_assign_to :state, :equals => "@il"
      should_assign_to :city, :equals => "@chicago"
      should_assign_to :query
      
      should "build query from parameters" do
        assert_equal "United States Illinois Chicago food", assigns(:query)
      end
    end
  end
end
