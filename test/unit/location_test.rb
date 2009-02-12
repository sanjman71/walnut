require 'test/test_helper'
require 'test/factories'

class LocationTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  should_belong_to            :country
  
  def setup
    @us           = Factory(:us)
    @ca           = Factory(:country, :name => "Canada", :code => "CA")
    @il           = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago      = Factory(:city, :name => "Chicago", :state => @il)
    @zip          = Factory(:zip, :name => "60654", :state => @il)
    @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
  end

  context "location with country" do
    setup do
      @location = Location.create(:name => "Home", :country => @us)
      @us.reload
    end
    
    should_change "Location.count", :by => 1
    
    should "have us as locality" do
      assert_equal [@us], @location.localities
    end
    
    should "have united states locality tag" do
      assert_equal ["United States"], @location.locality_tag_list
    end

    should "increment us locations_count" do
      assert_equal 1, @us.locations_count
    end
    
    context "remove country" do
      setup do
        @location.country = nil
        @location.save
        @us.reload
      end

      should "have us no localities" do
        assert_equal [], @location.localities
      end

      should "have no locality tags" do
        assert_equal [], @location.locality_tag_list
      end

      should "decrement us locations_count" do
        assert_equal 0, @us.locations_count
      end
    end
    
    context "change country" do
      setup do
        @location.country = @ca
        @location.save
        @ca.reload
      end

      should "have ca country area tag" do
        assert_equal ["Canada"], @location.locality_tag_list
      end

      should "increment ca locations_count" do
        assert_equal 1, @ca.locations_count
      end
    end
  end
  
  context "location with state" do
    setup do
      @location = Location.create(:name => "Home", :state => @il)
      @il.reload
    end
    
    should_change "Location.count", :by => 1
    
    should "have illinois locality tag" do
      assert_equal ["Illinois"], @location.locality_tag_list
    end

    should "increment illinois locations_count" do
      assert_equal 1, @il.locations_count
    end
    
    context "remove state" do
      setup do
        @location.state = nil
        @location.save
        @il.reload
      end
  
      should "have no illinois locality tag" do
        assert_equal [], @location.locality_tag_list
      end

      should "decrement illinois locations_count" do
        assert_equal 0, @il.locations_count
      end
    end
  end
  
  context "location with city" do
    setup do
      @location = Location.create(:name => "Home", :city => @chicago)
      @chicago.reload
    end
    
    should_change "Location.count", :by => 1
    
    should "have chicago locality tag" do
      assert_equal ["Chicago"], @location.locality_tag_list
    end
    
    should "increment chicago locations_count" do
      assert_equal 1, @chicago.locations_count
    end
    
    context "remove city" do
      setup do
        @location.city = nil
        @location.save
        @chicago.reload
      end
  
      should "have no locality tags" do
        assert_equal [], @location.locality_tag_list
      end

      should "decrement chicago locations_count" do
        assert_equal 0, @chicago.locations_count
      end
    end
  end
  
  context "location with zip" do
    setup do
      @location = Location.create(:name => "Home", :zip => @zip)
      @zip.reload
    end
    
    should_change "Location.count", :by => 1
    
    should "have 60654 locality tag" do
      assert_equal ["60654"], @location.locality_tag_list
    end
    
    should "increment zip locations_count" do
      assert_equal 1, @zip.locations_count
    end
    
    context "remove zip" do
      setup do
        @location.zip = nil
        @location.save
        @zip.reload
      end
  
      should "have no locality tags" do
        assert_equal [], @location.locality_tag_list
      end

      should "decrement zip locations_count" do
        assert_equal 0, @zip.locations_count
      end
    end
  end
  
  context "location with neighborhoods" do
    setup do
      @location = Location.create(:name => "Home")
      @location.neighborhoods.push(@river_north)
      @location.reload
      @river_north.reload
    end
    
    should_change "Location.count", :by => 1
  
    should "have neighborhood locality" do
      assert_equal [@river_north], @location.localities
    end
    
    should "have neighborhood locality tag" do
      assert_equal ["River North"], @location.locality_tag_list
    end
    
    should "increment neighborhood and locations counter caches" do
      assert_equal 1, @river_north.locations_count
      assert_equal 1, @location.neighborhoods_count
    end
  
    context "remove neighborhood" do
      setup do
        @location.neighborhoods.delete(@river_north)
        @location.reload
        @river_north.reload
      end

      should "have no locality tag" do
        assert_equal [], @location.locality_tag_list
      end
    end
  end
end
