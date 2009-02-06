require 'test/test_helper'
require 'test/factories'

class PlacesControllerTest < ActionController::TestCase
  
  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
  end
  
  context "place area, tag routes" do
    # country route
    should_route :get, '/places/us', :controller => 'places', :action => 'index', :country => 'us'
    # country, tag route
    should_route :get, '/places/us/food', :controller => 'places', :action => 'index', :country => 'us', :tag => 'food'
    # city route
    should_route :get, '/places/us/il/chicago', :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago'
    # city, tag route
    should_route :get, '/places/us/il/chicago/food',
                 :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
    # city with hyphen, tag route
    should_route :get, '/places/us/ny/new-york/food',
                 :controller => 'places', :action => 'index', :country => 'us', :state => 'ny', :city => 'new-york', :tag => 'food'
    # state route
    should_route :get, '/places/us/il/anywhere',
                 :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'anywhere'
    # state, tag route
    should_route :get, '/places/us/il/anywhere/food',
                 :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'anywhere', :tag => 'food'
    # zip route
    should_route :get, '/places/us/il/60610', 
                 :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :zip => '60610'
    # zip, tag route
    should_route :get, '/places/us/il/60610/food', 
                 :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food'
  end
  
  context "search city" do
    context "with no addresses" do
      setup do
        Address.stubs(:search).returns([])
        get :index, :country => @us.to_param, :state => @il.to_param, :city => @chicago.to_param
      end
    
      should_respond_with :success
      should_render_template 'places/index.html.haml'
      should_assign_to :country, :equals => "@us"
      should_assign_to :state, :equals => "@il"
      should_assign_to :city, :equals => "@chicago"
      should_assign_to :query
      
      should "build query" do
        assert_equal "United States Illinois Chicago", assigns(:query)
      end
    end
  end
end
