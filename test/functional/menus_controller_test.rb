require 'test/test_helper'

class MenusControllerTest < ActionController::TestCase

  should_route :get, '/menus', :controller => 'menus', :action => 'country'
  should_route :get, '/menus/us/il/chicago',
               :controller => 'menus', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago'
  should_route :get, '/menus/us/il/chicago/n/river-north',
               :controller => 'menus', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north'
  should_route :get, '/menus/us/il/chicago/tag/diner',
               :controller => 'menus', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'diner'
  should_route :get, '/menus/us/il/chicago/n/river-north/tag/diner',
               :controller => 'menus', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north',
               :tag => 'diner'

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)
    @rnorth   = Factory(:neighborhood, :name => "River North", :city => @chicago)
    @tag      = Tag.create(:name => 'food')
    @company  = Company.create(:name => "My Company", :time_zone => "UTC")
    @location = Location.create(:name => "Home", :country => @us, :state => @il, :city => @chicago, :street_address => '100 W Grand Ave',
                                :lat => 41.891737, :lng => -87.631483)
    @company.locations.push(@location)
    @location.tag_list.add('menu')
    @location.save
    @menu_tag = Tag.find_by_name('menu')
  end
  
  context "index" do
    context "city" do
      setup do
        # stub search results
        @results = [@location]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :index, :country => 'us', :state => 'il', :city => 'chicago'
      end

      should_assign_to(:city) { @chicago }
      should_not_assign_to(:tag)
      should_assign_to(:menu_tag) { @menu_tag }
      should_assign_to(:search_tags) { [@menu_tag] }
      should_assign_to(:exclude_tags) { ['menu'] }

      should_assign_to(:title) { "Menus near Chicago, IL" }
      should_assign_to(:h1) { "Restaurants in Chicago" }

      should_respond_with :success
      should_render_template 'menus/index.html.haml'
    end

    context "city with tag" do
      setup do
        @location.tag_list.add('pizza')
        @location.save
        @pizza_tag = Tag.find_by_name('pizza')
        # stub search results
        @results = [@location]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :index, :country => 'us', :state => 'il', :city => 'chicago', :tag => 'pizza'
      end

      should_assign_to(:city) { @chicago }
      should_assign_to(:tag) { @pizza_tag }
      should_assign_to(:menu_tag) { @menu_tag }
      should_assign_to(:search_tags) { [@menu_tag, @pizza_tag] }
      should_assign_to(:exclude_tags) { ['menu', 'pizza'] }

      should_assign_to(:title) { "Pizza Menus near Chicago, IL" }
      should_assign_to(:h1) { "Pizza Restaurants in Chicago" }

      should_respond_with :success
      should_render_template 'menus/index.html.haml'
    end

    context "neighborhood" do
      setup do
        # stub search results
        @results = [@location]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :index, :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north'
      end

      should_assign_to(:city) { @chicago }
      should_assign_to(:neighborhood) { @rnorth }
      should_not_assign_to(:tag)
      should_assign_to(:menu_tag) { @menu_tag }
      should_assign_to(:search_tags) { [@menu_tag] }
      should_assign_to(:exclude_tags) { ['menu'] }

      should_assign_to(:title) { "Menus near River North, Chicago, IL" }
      should_assign_to(:h1) { "Restaurants in River North, Chicago" }

      should_respond_with :success
      should_render_template 'menus/index.html.haml'
    end

    context "neighborhood with tag" do
      setup do
        @location.tag_list.add('pizza')
        @location.save
        @pizza_tag = Tag.find_by_name('pizza')
        # stub search results
        @results = [@location]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :index, :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', :tag => 'pizza'
      end

      should_assign_to(:title) { "Pizza Menus near River North, Chicago, IL" }
      should_assign_to(:h1) { "Pizza Restaurants in River North, Chicago" }

      should_respond_with :success
      should_render_template 'menus/index.html.haml'
    end
  end

end