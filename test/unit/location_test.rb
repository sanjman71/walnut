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
    @area_us      = Locality.create(:extent => @us)
    @area_ca      = Locality.create(:extent => @ca)
    @area_il      = Locality.create(:extent => @il)
    @area_chicago = Locality.create(:extent => @chicago)
    @area_zip     = Locality.create(:extent => @zip)
    @area_hood    = Locality.create(:extent => @river_north)
  end

  context "location with country" do
    setup do
      @location = Location.create(:name => "Home", :country => @us)
    end
    
    should_change "Location.count", :by => 1
    should_change "LocalityLocation.count", :by => 1
    
    should "have united states locality" do
      assert_equal [@area_us], @location.localities
    end

    should "have united states locality tag" do
      assert_equal ["United States"], @location.locality_tag_list
    end

    context "remove country" do
      setup do
        @location.country = nil
        @location.save
      end

      should_change "LocalityLocation.count", :by => -1

      should "have no areas" do
        assert_equal [], @location.localities
      end
      
      should "have no area tags" do
        assert_equal [], @location.locality_tag_list
      end
    end
    
    context "change country" do
      setup do
        @location.country = @ca
        @location.save
      end

      should_not_change "LocalityLocation.count"

      should "have ca country area" do
        assert_equal [@area_ca], @location.localities
      end
      
      should "have ca country area tag" do
        assert_equal ["Canada"], @location.locality_tag_list
      end
    end
  end
  
  context "location with state" do
    setup do
      @location = Location.create(:name => "Home", :state => @il)
    end
    
    should_change "Location.count", :by => 1
    should_change "LocalityLocation.count", :by => 1
    
    should "have illinois area" do
      assert_equal [@area_il], @location.localities
    end
    
    should "have illinois area tag" do
      assert_equal ["Illinois"], @location.locality_tag_list
    end
    
    context "remove state" do
      setup do
        @location.state = nil
        @location.save
      end

      should_change "LocalityLocation.count", :by => -1

      should "have no areas" do
        assert_equal [], @location.localities
      end
    end
  end

  context "location with city" do
    setup do
      @location = Location.create(:name => "Home", :city => @chicago)
    end
    
    should_change "Location.count", :by => 1
    should_change "LocalityLocation.count", :by => 1
    
    should "have chicago locality" do
      assert_equal [@area_chicago], @location.localities
    end

    should "have chicago locality tag" do
      assert_equal ["Chicago"], @location.locality_tag_list
    end
    
    context "remove city" do
      setup do
        @location.city = nil
        @location.save
      end

      should_change "LocalityLocation.count", :by => -1

      should "have no localities" do
        assert_equal [], @location.localities
      end

      should "have no locality tags" do
        assert_equal [], @location.locality_tag_list
      end
    end
  end

  context "location with zip" do
    setup do
      @location = Location.create(:name => "Home", :zip => @zip)
    end
    
    should_change "Location.count", :by => 1
    should_change "LocalityLocation.count", :by => 1
    
    should "have 60654 locality" do
      assert_equal [@area_zip], @location.localities
    end

    should "have 60654 locality tag" do
      assert_equal ["60654"], @location.locality_tag_list
    end
    
    context "remove zip" do
      setup do
        @location.zip = nil
        @location.save
      end

      should_change "LocalityLocation.count", :by => -1

      should "have no localities" do
        assert_equal [], @location.localities
      end

      should "have no locality tags" do
        assert_equal [], @location.locality_tag_list
      end
    end
  end
  
  context "address with 4 areas" do
    setup do
      @location = Location.create(:name => "Location 1")
      @location.localities.push(@area_us)
      @location.localities.push(@area_il)
      @location.localities.push(@area_chicago)
      @location.localities.push(@area_zip)
      @location.reload
    end
    
    should_change "Location.count", :by => 1
    
    should "have 4 areas" do
      assert_equal [@area_us, @area_il, @area_chicago, @area_zip], @location.localities
    end
  
    should "have 4 area tags" do
      assert_same_elements ["60654", "Chicago", "Illinois", "United States"], @location.locality_tag_list
    end

    context "with zip locality removed" do
      setup do
        @location.localities.delete(@area_zip)
        @location.save
        @location.reload
      end
  
      should "have 3 localities" do
        assert_same_elements [@area_chicago, @area_il, @area_us], @location.localities
      end
  
      should "have 3 locality tags" do
        assert_same_elements ["Chicago", "Illinois", "United States"], @location.locality_tag_list
      end
      
      should "have empty zip" do
        assert_equal nil, @location.zip
      end
      
      context "with neighborhood locality added" do
        setup do
          @location.localities.push(@area_hood)
          @location.reload
        end
        
        should "have river north locality" do
          assert_same_elements [@area_hood, @area_chicago, @area_il, @area_us], @location.localities
        end
        
        should "have river north locality tag" do
          assert_same_elements ["River North", "Chicago", "Illinois", "United States"], @location.locality_tag_list
        end
      end
    end
  end
end
