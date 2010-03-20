require 'test/test_helper'

class SpecialsControllerTest < ActionController::TestCase

  should_route :get, '/specials', :controller => 'specials', :action => 'index'
  should_route :get, '/specials/us/il/chicago', 
               :controller => 'specials', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  should_route :get, '/specials/us/il/chicago/monday',
               :controller => 'specials', :action => 'city_day', :country => 'us', :state => 'il', :city => 'chicago', :day => 'monday'

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
    setup_special
  end

  def setup_special
    @start_at     = DateRange.find_next_date("monday")
    @end_at       = @start_at.end_of_day
    @recur_rule   = "FREQ=WEEKLY;BYDAY=MO";
    @special      = Special.create("Monday Happy Hour", @location, @recur_rule, :start_at => @start_at, :end_at => @end_at,
                                   :preferences => {:special_drink => '$1 well drinks'})
    @tag_special  = Tag.find_by_name('special')
    @tag_monday   = Tag.find_by_name('monday')
  end

  context "city specials" do
    context "no day" do
      setup do
        get :city, :controller => 'specials', :country => 'us', :state => 'il', :city => 'chicago'
      end

      should_not_assign_to(:tags)
      should_not_assign_to(:attributes)
      should_not_assign_to(:specials)
      should_assign_to(:title) { "Chicago Specials" }

      should_respond_with :success
      should_render_template 'specials/city.html.haml'
    end

    context "weekly" do
      setup do
        # stub search results
        @results = [@special]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :city_day, :controller => 'specials', :country => 'us', :state => 'il', :city => 'chicago', :day => 'weekly'
      end

      should_assign_to(:tags) { [@tag_special] }
      should_assign_to(:keywords) { ['drink'] }
      should_assign_to(:attributes) { Hash[:tag_ids => [@tag_special.id], :city_id => @chicago.id] }
      should_assign_to(:specials) { [@special] }
      should_assign_to(:title) { "Chicago Weekly Specials" }

      should_respond_with :success
      should_render_template 'specials/city_day.html.haml'
    end

    context "monday" do
      setup do
        # stub search results
        @results = [@special]
        ThinkingSphinx.stubs(:search).returns(@results)
        @results.stubs(:total_pages).returns(1)
        get :city_day, :controller => 'specials', :country => 'us', :state => 'il', :city => 'chicago', :day => 'monday'
      end

      should_assign_to(:tags) { [@tag_special, @tag_monday] }
      should_assign_to(:keywords) { ['drink'] }
      should_assign_to(:attributes) { Hash[:tag_ids => [@tag_special.id, @tag_monday.id], :city_id => @chicago.id] }
      should_assign_to(:specials) { [@special] }
      should_assign_to(:title) { "Chicago Monday Specials" }

      should_respond_with :success
      should_render_template 'specials/city_day.html.haml'
    end
  end
  
end