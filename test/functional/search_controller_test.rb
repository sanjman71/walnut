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
    @z60610   = Factory(:zip, :name => "60610", :state => @il)
  end

  context "city search tag page" do
    context "with no locations" do
      setup do
        # ThinkingSphinx::Collection takes 4 arguments: page, per_page, entries, total_entries
        ThinkingSphinx::Search.stubs(:search).returns(ThinkingSphinx::Collection.new(1, 1, 0, 0))
        get :index, :klass => 'search', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
      end
    
      should_respond_with :success
      should_render_template 'search/no_results.html.haml'
      should_assign_to(:klasses) { [Location] }
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to :query, :tag
      should_assign_to(:query_or) { "food" }
      should_assign_to(:query_and) { "food" }
      should_assign_to(:query_raw) { "food" }
      should_not_assign_to(:fields)
      should_assign_to(:attributes) { Hash[:city_id => @chicago.id, :state_id => @il.id, :country_id => @us.id] }
      should_assign_to(:title) { "Food near Chicago, IL" }
      should_assign_to(:h1) { "Food near Chicago, IL" }
      
      should "have breadcrumbs link 'United States'" do
        assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                                 :descendant => {:tag => 'a', :attributes => {:class => 'country', :href => '/search/us'}}
      end

      should "have breadcrumbs link 'Illinois'" do
        assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                                 :descendant => {:tag => 'a', :attributes => {:class => 'state', :href => '/search/us/il'}}
      end

      should "have breadcrumbs link 'Chicago'" do
        assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                                 :descendant => {:tag => 'a', :attributes => {:class => 'city', :href => '/search/us/il/chicago'}}
      end
    end
  end

  context "city page with no zips or neighborhoods" do
    setup do
      # stub zip, tags facet search
      Search.stubs(:load_from_facets).returns([])
      get :city, :country => 'us', :state => 'il', :city => 'chicago'
    end

    should_respond_with :success
    should_render_template 'search/city.html.haml'
    should_assign_to(:country) { @us }
    should_assign_to(:state) { @il }
    should_assign_to(:city) { @chicago }
    should_assign_to(:zips) { [] }
    should_assign_to(:neighborhoods) { [] }
    should_assign_to(:title) { "Chicago, IL Yellow Pages" }
    should_assign_to(:h1) { "Search Places and Events in Chicago, Illinois" }

    should "have h1 tag" do
      assert_tag :tag => "h1", :content => "Search Places and Events in Chicago, Illinois"
    end
    
    should "have search anything link" do
      assert_tag :tag => "h5", :descendant => {:tag => 'a', :attributes => {:href => '/search/us/il/chicago/tag/anything'}}
    end
    
    should "have breadcrumbs link 'United States'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'a', :attributes => {:class => 'country', :href => '/search/us'}}
    end

    should "have breadcrumbs link 'Illinois'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'a', :attributes => {:class => 'state', :href => '/search/us/il'}}
    end

    should "have breadcrumbs name 'Chicago'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'span', :attributes => {:class => 'city'}}
    end
  end
  
  context "neighborhood page" do
    setup do
      @river_north = Factory(:neighborhood, :name => "River North", :city => @chicago)
      # stub tags facet search
      Search.stubs(:load_from_facets).returns([])
      get :neighborhood, :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north'
    end

    should_respond_with :success
    should_render_template 'search/neighborhood.html.haml'
    should_assign_to(:country) { @us }
    should_assign_to(:state) { @il }
    should_assign_to(:city) { @chicago }
    should_assign_to(:neighborhood) { @river_north }
    should_assign_to(:title) { "River North, Chicago, IL Yellow Pages" }
    should_assign_to(:h1) { "Search Places and Events in River North, Chicago, Illinois" }

    should "have h1 tag" do
      assert_tag :tag => "h1", :content => "Search Places and Events in River North, Chicago, Illinois"
    end

    should "have breadcrumbs link 'United States'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'a', :attributes => {:class => 'country', :href => '/search/us'}}
    end

    should "have breadcrumbs link 'Illinois'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'a', :attributes => {:class => 'state', :href => '/search/us/il'}}
    end

    should "have breadcrumbs link 'Chicago'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'a', :attributes => {:class => 'city', :href => '/search/us/il/chicago'}}
    end

    should "have breadcrumbs name 'Rvier North'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'span', :attributes => {:class => 'neighborhood'}}
    end
  end

  context "zip page" do
    setup do
      # stub cities, tags facet search
      Search.stubs(:load_from_facets).returns([])
      get :zip, :country => 'us', :state => 'il', :zip => '60610'
    end
    
    should_respond_with :success
    should_render_template 'search/zip.html.haml'
    should_assign_to(:country) { @us }
    should_assign_to(:state) { @il }
    should_assign_to(:zip) { @z60610 }
    should_assign_to(:cities) { [] }
    should_assign_to(:title) { "IL 60610 Yellow Pages" }
    should_assign_to(:h1) { "Search Places and Events in IL 60610" }

    should "have h1 tag" do
      assert_tag :tag => "h1", :content => "Search Places and Events in IL 60610"
    end

    should "have breadcrumbs link 'United States'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'a', :attributes => {:class => 'country', :href => '/search/us'}}
    end

    should "have breadcrumbs link 'Illinois'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'a', :attributes => {:class => 'state', :href => '/search/us/il'}}
    end

    should "have breadcrumbs name '60610'" do
      assert_tag :tag => "h4", :attributes => {:id => 'breadcrumbs'}, 
                               :descendant => {:tag => 'span', :attributes => {:class => 'zip'}}
    end
  end
end