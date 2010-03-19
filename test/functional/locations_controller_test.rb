require 'test/test_helper'

class LocationsControllerTest < ActionController::TestCase

  should_route :post, '/locations/1/recommend', :controller => 'locations', :action => 'recommend', :id => '1'
  should_route :get, '/locations/chicago/random', :controller => 'locations', :action => 'random', :city => 'chicago'

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @loop     = Factory(:city, :name => "Loop", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)
    @z60614   = Factory(:zip, :name => "60614", :state => @il)

    @location = Location.create(:street_address => "200 W Grand Ave", :city => @chicago, :state => @il, :country => @us)
    @company = Company.create(:name => "Chicago Pizza", :time_zone => "UTC")
    @company.locations.push(@location)
  end

  context "show" do
    setup do
      ThinkingSphinx.stubs(:search).returns([@location])
      get :show, :id => @location.to_param
    end

    should_assign_to(:location) { @location }
    should_assign_to(:company) { @company }

    should_respond_with :success
    should_render_template 'locations/show.html.haml'

    should_assign_to(:title) { "Chicago Pizza - Chicago IL" }
    should_assign_to(:h1) { "Chicago Pizza" }

    should "have h1 tag" do
      assert_tag :tag => "h1", :content => "Chicago Pizza"
    end
  end

  context "edit" do
    setup do
      get :edit, :id => @location.to_param
    end

    should_assign_to(:location) { @location }
    should_assign_to(:company) { @company }
    should_assign_to(:countries) { [@us] }
    should_assign_to(:states) { [@il] }
    should_assign_to(:cities) { [@chicago, @loop] }
    should_assign_to(:zips) { [@z60610, @z60614] }

    should_respond_with :success
    should_render_template 'locations/edit.html.haml'
  end
  
  context "update" do
    context "company name" do
      setup do
        Location.any_instance.expects(:geocode_latlng).never
        put :update, :id => @location.to_param, :location => {:company_attributes => {:id => @company.id, :name => "Chicago Soccer"}}
      end

      should_assign_to(:location) { @location }
      should_assign_to(:company) { @company }

      should "change company name" do
        assert_equal 'Chicago Soccer', @company.reload.name
      end
    end

    context "city" do
      setup do
        Location.any_instance.expects(:geocode_latlng).once
        put :update, :id => @location.to_param, :location => {:city_id => @loop.id}
      end

      should_assign_to(:location) { @location }
      should_assign_to(:company) { @company }

      should "change location city" do
        assert_equal @loop, assigns(:location).reload.city
      end

      should_change("city loop location count", :by => 1) { @loop.reload.locations_count }
      should_change("city chicago location count", :by => -1) { @chicago.reload.locations_count }

      should_redirect_to("show location") { "/locations/#{@location.to_param}" }
    end

    context "add zip" do
      setup do
        Location.any_instance.expects(:geocode_latlng).once
        put :update, :id => @location.to_param, :location => {:zip_id => @z60614.id}
      end

      should_assign_to(:location) { @location }
      should_assign_to(:company) { @company }

      should "change location zip" do
        assert_equal @z60614, assigns(:location).reload.zip
      end

      should_not_change("zip 60610 location count") { @z60610.reload.locations_count }
      should_change("zip 60614 location count", :by => 1) { @z60614.reload.locations_count }

      should_redirect_to("show location") { "/locations/#{@location.to_param}" }
    end

    context "phone number" do
      setup do
        @phone = @location.phone_numbers.create(:name => "Mobile", :address => "3125551212")
        put :update, :id => @location.to_param,
            :location => {:phone_numbers_attributes => {"0" => {:id => @phone.id, :name => "Work", :address => "7043981488"}}}
      end

      should_assign_to(:location) { @location }
      should_assign_to(:company) { @company }

      should "not change location.phone_numbers_count" do
        assert_equal 1, @location.reload.phone_numbers_count
      end

      should "change location phone number" do
        assert_equal "7043981488", @location.reload.primary_phone_number.address
      end
    end

    context "email" do
      setup do
        @email = @location.email_addresses.create(:address => "email@jarna.com")
        put :update, :id => @location.to_param,
            :location => {:email_addresses_attributes => {"0" => {:id => @email.id, :address => "baz@jarna.com"}}}
      end
    
      should_assign_to(:location) { @location }
      should_assign_to(:company) { @company }
    
      should "change location email" do
        assert_equal "baz@jarna.com", @location.reload.primary_email_address.address
      end
    end
  end
end