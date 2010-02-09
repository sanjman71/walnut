require 'test/test_helper'

class ZipsControllerTest < ActionController::TestCase
  
  # zip routes
  should_route :get, '/zips/us', :controller => 'zips', :action => 'country', :country => 'us'
  should_route :get, '/zips/us/il', :controller => 'zips', :action => 'state', :country => 'us', :state => 'il'
  should_route :get, '/zips/us/il/60654', :controller => 'zips', :action => 'zip', :country => 'us', :state => 'il', :zip => '60654'
  should_route :get, '/zips/us/il/chicago', :controller => 'zips', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)
    @location = Factory(:location, :country => @us, :state => @il, :city => @chicago, :zip => @z60610)
  end

  context "country" do
    setup do
      get :country, :country => 'us'
    end
    
    should_assign_to(:country) { @us }
    should_assign_to(:states)
    should_assign_to(:h1) { "Find Zips by State" }
    should_assign_to(:title) { "United States Zip Code Finder" }

    should_render_template("zips/country.html.haml")
  end

  context "state" do
    setup do
      get :state, :country => 'us', :state => 'il'
    end

    should_assign_to(:country) { @us }
    should_assign_to(:state) { @il }
    should_assign_to(:cities) { [@chicago] }
    should_assign_to(:zips) { [@z60610] }

    should_assign_to(:h1) { "Illinois Zip Code Directory" }
    should_assign_to(:title) { "Illinois Zip Code Finder" }

    should_render_template("zips/state.html.haml")

    should "have breadcrumbs link 'United States'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'},
                               :descendant => {:tag => 'a', :attributes => {:class => 'country', :href => '/zips/us'}}
    end
  end

  context "zip" do
    setup do
      Zip.any_instance.stubs(:cities).returns([@chicago])
      get :zip, :country => 'us', :state => 'il', :zip => '60610'
    end

    should_assign_to(:country) { @us }
    should_assign_to(:state) { @il }
    should_assign_to(:zip) { @z60610 }
    should_assign_to(:cities) { [@chicago] }

    should_assign_to(:h1) { "60610 IL Zip Code" }
    should_assign_to(:title) { "Illinois 60610 Zip Code" }

    should_render_template("zips/zip.html.haml")

    should "have breadcrumbs link 'United States'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'},
                               :descendant => {:tag => 'a', :attributes => {:class => 'country', :href => '/zips/us'}}
    end

    should "have breadcrumbs link 'Illinois'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'},
                               :descendant => {:tag => 'a', :attributes => {:class => 'state', :href => '/zips/us/il'}}
    end
  end
end