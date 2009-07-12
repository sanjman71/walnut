require 'test/test_helper'
require 'test/factories'

class LocationsControllerTest < ActionController::TestCase
  
  should_route :post, '/locations/1/recommend', :controller => 'locations', :action => 'recommend', :id => '1'

  should_route :get, '/locations/chicago/random', :controller => 'locations', :action => 'random', :city => 'chicago'

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)
  end

  context "show location" do
    setup do
      @location = Location.create(:country => @us, :state => @il, :city => @chicago, :zip => @zip)
      @place    = Place.create(:name => "Chicago Pizza")
      @place.locations.push(@location)
      # ThinkingSphinx::Collection takes 4 arguments: page, per_page, entries, total_entries
      # ThinkingSphinx::Search.stubs(:search).returns(ThinkingSphinx::Collection.new(1, 1, 0, 0))
      get :show, :id => @location.to_param
    end
    
    should_respond_with :success
    should_render_template 'locations/show.html.haml'

    should_assign_to(:title) { "Chicago Pizza - Chicago IL" }
    should_assign_to(:h1) { "Chicago Pizza" }

    should "have h1 tag" do
      assert_tag :tag => "h1", :content => "Chicago Pizza"
    end
  end
end