require 'test/test_helper'
require 'test/factories'

class SearchControllerTest < ActionController::TestCase

  # search resolve route
  should_route :post, '/search/resolve', :controller => 'search', :action => 'resolve'
  
  # state route
  should_route :get, '/search/us/il', :controller => 'search', :action => 'state', :country => 'us', :state => 'il'
  should_route :get, '/search/us/il/q/pizza', :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :query => 'pizza'
  
  # city route
  should_route :get, '/search/us/il/chicago', :controller => 'search', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  
  # city search tag/query routes
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

  # neighborhood search tag/query routes
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

   # lat/lng with or without street search tag/query routes
   should_route :get, '/search/us/il/chicago/x/41891133/y/-87634015/q/food',
                :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :lat => '41891133', :lng => '-87634015',
                :query => 'food', :klass => 'search'
   should_route :get, '/search/us/il/chicago/x/41891133/y/-87634015/tag/food',
                :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :lat => '41891133', :lng => '-87634015',
                :tag => 'food', :klass => 'search'
   should_route :get, '/search/us/il/chicago/s/200-w-grand-ave/x/41891133/y/-87634015/q/food',
                :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :lat => '41891133', :lng => '-87634015',
                :street => '200-w-grand-ave', :query => 'food', :klass => 'search'
   should_route :get, '/search/us/il/chicago/s/200-w-grand-ave/x/41891133/y/-87634015/tag/food',
                :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :lat => '41891133', :lng => '-87634015',
                :street => '200-w-grand-ave', :tag => 'food', :klass => 'search'

  # error route
  should_route :get, '/search/error/country', :controller => 'search', :action => 'error', :locality => 'country'
  should_route :get, '/search/error/unknown', :controller => 'search', :action => 'error', :locality => 'unknown'

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)
    @tag      = Tag.create(:name => 'food')
    @company  = Company.create(:name => "My Company", :time_zone => "UTC")
    @location = Location.create(:name => "Home", :country => @us, :state => @il, :city => @chicago, :street_address => '100 W Grand Ave',
                                :lat => 41.891737, :lng => -87.631483)
    @company.locations.push(@location)
  end

  context "city search without street and lat/lng" do
    context "with query 'anything' and 1 location" do
      setup do
        # stub search results
        @results = [@location]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :index, :klass => 'search', :country => 'us', :state => 'il', :city => 'chicago', :query => 'anything'
      end

      should_respond_with :success
      should_render_template 'search/index.html.haml'
      should_assign_to(:klasses) { [Location] }
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to(:geo_search) { 'city' }
      should_assign_to(:query) { 'anything' }
      should_not_assign_to(:tag)
      should_assign_to(:query_or) { "" }
      should_assign_to(:query_and) { "" }
      should_assign_to(:query_quorum) { "" }
      should_assign_to(:query_raw) { "anything" }
      should_not_assign_to(:fields)
      should_assign_to(:attributes) { Hash[:city_id => @chicago.id] }
      should_assign_to(:title) { "Places Directory near Chicago, IL" }
      should_assign_to(:h1) { "Places Directory near Chicago, IL" }

      should "allow robots" do
        assert_true assigns(:robots)
      end

      should "have robots meta tag index,follow" do
        assert_select "meta[name='robots']" do
          assert_select "[content=?]", "index,follow"
        end
      end
    end

    context "with query and no locations" do
      setup do
        # stub search results
        ThinkingSphinx.stubs(:search).returns([])
        get :index, :klass => 'search', :country => 'us', :state => 'il', :city => 'chicago', :query => 'food'
      end

      should_respond_with :success
      should_render_template 'search/no_results.html.haml'
      should_assign_to(:klasses) { [Location] }
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to(:geo_search) { 'city' }
      should_assign_to(:query) { 'food' }
      should_not_assign_to(:tag)
      should_assign_to(:query_or) { "food" }
      should_assign_to(:query_and) { "food" }
      should_assign_to(:query_quorum) { "\"food\"/1" }
      should_assign_to(:query_raw) { "food" }
      should_not_assign_to(:fields)
      should_assign_to(:attributes) { Hash[:city_id => @chicago.id] }
      should_assign_to(:title) { "Food near Chicago, IL" }
      should_assign_to(:h1) { "Food near Chicago, IL" }

      should "disallow robots (query, no locations)" do
        assert_false assigns(:robots)
      end

      should "have robots meta tag noindex,nofollow" do
        assert_select "meta[name='robots']" do
          assert_select "[content=?]", "noindex,nofollow"
        end
      end
    end

    context "with tag and no locations" do
      setup do
        # stub search results
        ThinkingSphinx.stubs(:search).returns([])
        get :index, :klass => 'search', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
      end
    
      should_respond_with :success
      should_render_template 'search/no_results.html.haml'
      should_assign_to(:klasses) { [Location] }
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to(:geo_search) { 'city' }
      should_assign_to(:query) { '' }
      should_assign_to(:tag) { @tag }
      should_assign_to(:query_or) { "" }
      should_assign_to(:query_and) { "" }
      should_assign_to(:query_quorum) { "" }
      should_assign_to(:query_raw) { "tags:food" }
      should_assign_to(:fields) { Hash[:tags => 'food'] }
      should_assign_to(:attributes) { Hash[:city_id => @chicago.id] }
      should_assign_to(:title) { "Food near Chicago, IL" }
      should_assign_to(:h1) { "Food near Chicago, IL" }

      should "disallow robots (no locations)" do
        assert_false assigns(:robots)
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
    end
    
    context "with tag and 1 location" do
      setup do
        # stub search results
        @results = [@location]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :index, :klass => 'search', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food'
      end

      should_respond_with :success
      should_render_template 'search/index.html.haml'
      should_assign_to(:objects) { [@location] }
      should_assign_to(:klasses) { [Location] }
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to(:geo_search) { 'city' }
      should_not_assign_to(:geo_origin)
      should_assign_to(:query) { '' }
      should_assign_to(:tag) { @tag }
      should_assign_to(:query_or) { "" }
      should_assign_to(:query_and) { "" }
      should_assign_to(:query_quorum) { "" }
      should_assign_to(:query_raw) { "tags:food" }
      # should_assign_to(:fields) { Hash[:tags => 'food'] }
      # should_assign_to(:attributes) { Hash[:city_id => @chicago.id] }

      should_assign_to(:sphinx_options, :class => Hash)

      should "set sphinx classes option" do
        @sphinx_options = assigns(:sphinx_options)
        assert_equal [Location], @sphinx_options[:classes]
      end

      should "set sphinx with option" do
        @sphinx_options = assigns(:sphinx_options)
        assert_equal Hash[:city_id => @chicago.id], @sphinx_options[:with]
      end

      should "set sphinx conditions option" do
        @sphinx_options = assigns(:sphinx_options)
        assert_equal Hash[:tags => 'food'], @sphinx_options[:conditions]
      end

      should "set sphinx order option" do
        @sphinx_options = assigns(:sphinx_options)
        assert_equal 'popularity desc, @relevance desc', @sphinx_options[:order]
      end

      should "set sphinx page options" do
        @sphinx_options = assigns(:sphinx_options)
        assert_equal 1, @sphinx_options[:page]
        assert_equal 10, @sphinx_options[:per_page]
        assert_equal 100, @sphinx_options[:max_matches]
      end

      should_assign_to(:title) { "Food near Chicago, IL" }
      should_assign_to(:h1) { "Food near Chicago, IL" }

      should "allow robots" do
        assert_true assigns(:robots)
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
    end
  end

  context "city search with street and lat/lng" do
    setup do
      # stub search results
      @results = [@location]
      ThinkingSphinx.stubs(:search).returns(@results)
      @results.stubs(:total_pages).returns(1)
      get :index, :klass => 'search', :country => 'us', :state => 'il', :city => 'chicago', :street => '100-w-grand-ave', 
          :lat => '41891737', :lng => '-87631483', :tag => 'food'
    end

    should_respond_with :success
    should_render_template 'search/index.html.haml'
    should_assign_to(:objects) { [@location] }
    should_assign_to(:klasses) { [Location] }
    should_assign_to(:country) { @us }
    should_assign_to(:state) { @il }
    should_assign_to(:city) { @chicago }
    should_assign_to(:street) { '100 W Grand Ave' }
    should_assign_to(:lat, :class => BigDecimal)
    should_assign_to(:lng, :class => BigDecimal)
    should_assign_to(:geo_search) { 'city' }
    should_assign_to(:geo_origin)

    should_assign_to(:sphinx_options, :class => Hash)

    should "set sphinx classes option" do
      @sphinx_options = assigns(:sphinx_options)
      assert_equal [Location], @sphinx_options[:classes]
    end

    should "set sphinx with option" do
      @sphinx_options = assigns(:sphinx_options)
      assert_equal Hash[:city_id => @chicago.id], @sphinx_options[:with]
    end

    should "set sphinx conditions option" do
      @sphinx_options = assigns(:sphinx_options)
      assert_equal Hash[:tags => 'food'], @sphinx_options[:conditions]
    end

    should "set sphinx order option" do
      @sphinx_options = assigns(:sphinx_options)
      assert_equal '@geodist asc', @sphinx_options[:order]
    end

    should "set sphinx page options" do
      @sphinx_options = assigns(:sphinx_options)
      assert_equal 1, @sphinx_options[:page]
      assert_equal 10, @sphinx_options[:per_page]
      assert_equal 100, @sphinx_options[:max_matches]
    end

    should_assign_to(:title) { "Food near 100 W Grand Ave, Chicago, IL" }
    should_assign_to(:h1) { "Food near 100 W Grand Ave, Chicago, IL" }
  end

  context "city with no zips or neighborhoods" do
    setup do
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
    
    # should "have search anything link" do
    #   assert_tag :tag => "h5", :descendant => {:tag => 'a', :attributes => {:href => '/search/us/il/chicago/tag/anything'}}
    # end
    
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
  
  context "neighborhood" do
    setup do
      @river_north = Factory(:neighborhood, :name => "River North", :city => @chicago)
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

  context "zip" do
    setup do
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