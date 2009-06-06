require 'test/test_helper'
require 'test/factories'

class LocationTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :name
  should_belong_to              :country
  
  def setup
    @us           = Factory(:us)
    @ca           = Factory(:country, :name => "Canada", :code => "CA")
    @il           = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago      = Factory(:city, :name => "Chicago", :state => @il)
    @zip          = Factory(:zip, :name => "60654", :state => @il)
    @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
    @place        = Place.create(:name => "My Place")
  end

  context "location with country" do
    setup do
      @location = Location.create(:name => "Home", :country => @us)
      @location.reload
      @us.reload
      @digest = @location.digest
    end
    
    should_change "Location.count", :by => 1
    
    should "have us as locality" do
      assert_equal [@us], @location.localities
    end
    
    should "have a valid digest" do
      assert_not_equal "", @digest
    end
    
    should "increment us locations_count" do
      assert_equal 1, @us.locations_count
    end

    should "have refer_to? == false" do
      assert_equal false, @location.refer_to?
    end
    
    context "remove country" do
      setup do
        @location.country = nil
        @location.save
        @location.reload
        @us.reload
        @digest2 = @location.digest
      end

      should "have us no localities" do
        assert_equal [], @location.localities
      end

      should "have a changed digest" do
        assert_not_equal @digest, @digest2
      end
      
      # should "have no locality tags" do
      #   assert_equal [], @location.locality_tag_list
      # end

      should "decrement us locations_count" do
        assert_equal 0, @us.locations_count
      end
    end
    
    context "change country" do
      setup do
        @location.country = @ca
        @location.save
        @location.reload
        @us.reload
        @ca.reload
        @digest2 = @location.digest
      end

      # should "have ca country area tag" do
      #   assert_equal ["Canada"], @location.locality_tag_list
      # end

      should "have a changed digest" do
        assert_not_equal @digest, @digest2
      end

      should "decrement us locations_count" do
        assert_equal 0, @us.locations_count
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
      @location.reload
      @digest = @location.digest
    end
    
    should_change "Location.count", :by => 1

    should "have a valid digest" do
      assert_not_equal "", @digest
    end

    should "increment illinois locations_count" do
      assert_equal 1, @il.locations_count
    end
    
    context "remove state" do
      setup do
        @location.state = nil
        @location.save
        @il.reload
        @location.reload
        @digest2 = @location.digest
      end

      should "have a changed digest" do
        assert_not_equal @digest, @digest2
      end

      should "decrement illinois locations_count" do
        assert_equal 0, @il.locations_count
      end
    end
  end
  
  context "location with a place and city" do
    setup do
      @location = Location.create(:name => "Home", :city => @chicago)
      @location.reload
      @digest = @location.digest
      assert_not_equal "", @digest
      @place.locations.push(@location)
      @place.reload
      @location.reload
      @chicago.reload
      @digest1 = @location.digest
      assert_not_equal @digest, @digest1
    end
    
    should_change "Location.count", :by => 1
    should_change "LocationPlace.count", :by => 1

    should "increment chicago locations_count" do
      assert_equal 1, @chicago.locations_count
    end

    should "set chicago locations to [@location]" do
      assert_equal [@location], @chicago.locations
    end

    context "remove city" do
      setup do
        @location.city = nil
        @location.save
        @chicago.reload
        @location.reload
        @digest2 = @location.digest
      end

      should "decrement chicago locations_count" do
        assert_equal 0, @chicago.locations_count
      end

      should "set chicago locations to []" do
        assert_equal [], @chicago.locations
      end

      should "have a changed digest" do
        assert_not_equal @digest1, @digest2
      end
    end
    
    context "change city" do
      setup do
        @springfield = Factory(:city, :name => "Springfield", :state => @il)
        @location.city = @springfield
        @location.save
        @chicago.reload
        @location.reload
        @digest2 = @location.digest
      end

      should "remove chicago locations" do
        assert_equal [], @chicago.locations
      end

      should "set springfield locations to [@location]" do
        assert_equal [@location], @springfield.locations
      end

      should "have a changed digest" do
        assert_not_equal @digest1, @digest2
      end
    end
    
    context "remove place" do
      setup do
        @place.locations.delete(@location)
        @location.reload
        @digest2 = @location.digest
      end

      should_change "LocationPlace.count", :by => -1
      
      should "leave chicago locations as [@location]" do
        assert_equal [@location], @chicago.locations
      end

      should "have no places associated with location" do
        assert_equal [], @location.places
      end
      
      should "have digest changed back to original digest" do
        assert_not_equal @digest1, @digest2
        assert_equal @digest, @digest2
      end
    end
  end
    
  context "location with a place and zip" do
    setup do
      @location = Location.create(:name => "Home", :zip => @zip)
      @place.locations.push(@location)
      @location.reload
      @zip.reload
      @digest = @location.digest
    end
    
    should_change "Location.count", :by => 1
    should_change "LocationPlace.count", :by => 1

    should "increment zip locations_count" do
      assert_equal 1, @zip.locations_count
    end

    should "set zip locations to [@location]" do
      assert_equal [@location], @zip.locations
    end
    
    should "have a valid digest" do
      assert_not_equal "", @digest
    end
    
    context "remove zip" do
      setup do
        @location.zip = nil
        @location.save
        @zip.reload
        @location.reload
        @digest2 = @location.digest
      end

      should "decrement zip locations_count" do
        assert_equal 0, @zip.locations_count
      end

      should "remove zip locations" do
        assert_equal [], @zip.locations
      end

      should "have a changed digest" do
        assert_not_equal @digest, @digest2
      end
    end
    
    context "change zip" do
      setup do
        @zip2 = Factory(:zip, :name => "60610", :state => @il)
        @location.zip = @zip2
        @location.save
        @zip2.reload
        @location.reload
        @digest2 = @location.digest
      end

      should "set 60654 locations to []" do
        assert_equal [], @zip.locations
      end
      
      should "set 60610 locations to [@location]" do
        assert_equal [@location], @zip2.locations
      end

      should "have a changed digest" do
        assert_not_equal @digest, @digest2
      end
    end
  end
  
  context "location with a place and neighborhood" do
    setup do
      @location = Location.create(:name => "Home")
      @location.neighborhoods.push(@river_north)
      @place.locations.push(@location)
      @location.reload
      @river_north.reload
    end
    
    should_change "Location.count", :by => 1
    should_change "LocationPlace.count", :by => 1
  
    should "have neighborhood locality" do
      assert_equal [@river_north], @location.localities
    end

    should "increment neighborhood and locations counter caches" do
      assert_equal 1, @river_north.locations_count
      assert_equal 1, @location.neighborhoods_count
    end
  
    should "set neighborhood locations to [@location]" do
      assert_equal [@location], @river_north.locations
    end
  
    context "remove neighborhood" do
      setup do
        @location.neighborhoods.delete(@river_north)
        @location.reload
        @river_north.reload
      end

      should "set neighborhood locations to []" do
        assert_equal [], @river_north.locations
      end
      
      should "decrement neighborhood and locations counter caches" do
        assert_equal 0, @river_north.locations_count
        assert_equal 0, @location.neighborhoods_count
      end
      
    end
  end
  
  context "location without refer_to" do
    setup do
      @location = Location.create(:name => "Home")
    end
    
    should "have refer_to? == false" do
      assert_equal false, @location.refer_to?
    end
    
    context "and add refer_to" do
      setup do
        @location.refer_to = 1001
        @location.save
      end

      should "have refer_to? == true" do
        assert_equal true, @location.refer_to?
      end
    end
  end
end
