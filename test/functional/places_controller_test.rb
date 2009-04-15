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
  # city tag route
  should_route :get, '/places/us/il/chicago/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :what => 'food'
  # hyphenated city tag route
  should_route :get, '/places/us/ny/new-york/food',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'ny', :city => 'new-york', :what => 'food'

  # neighborhood route
  should_route :get, '/places/us/il/chicago/n/river-north', 
               :controller => 'places', :action => 'neighborhood', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north'

  # neighborhood tag route
  should_route :get, '/places/us/il/chicago/n/river-north/soccer', 
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', :what => 'soccer'
  
  # zip route
  should_route :get, '/places/us/il/60610', 
               :controller => 'places', :action => 'zip', :country => 'us', :state => 'il', :zip => '60610'
  # zip tag route
  should_route :get, '/places/us/il/60610/food', 
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :what => 'food'
  
  # show route
  should_route :get, '/places/1', :controller => 'places', :action => 'show', :id => 1
  
  # city rcommended route
  should_route :get, '/recommended/places/us/il/chicago',
               :controller => 'places', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :filter => 'recommended' 
  
  # error route
  should_route :get, '/places/error/country', :controller => 'places', :action => 'error', :area => 'country'
  
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
      should_assign_to :what
      should_assign_to :search
      should_assign_to :tags
      should_assign_to :title
      
      should "have tags ['food']" do
        assert_equal ["food"], assigns(:tags)
      end
      
      should "have title 'Food near Chicago, Illinois'" do
        assert_equal 'Food near Chicago, Illinois', assigns(:title)
      end
    end
  end
end
