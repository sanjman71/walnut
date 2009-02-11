require 'test/test_helper'
require 'test/factories'

class PlaceTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  should_have_many            :locations
  should_belong_to            :chain
  
  context "create place with an address" do
    setup do
      @place    = Place.create(:name => "Place 1")
      @location = Location.create(:name => "Home")
      @place.locations.push(@location)
      @place.reload
    end
    
    should_change "Place.count", :by => 1
    should_change "Location.count", :by => 1
    
    should "have 1 address" do
      assert_equal [@location], @place.locations
    end
    
    should "have locations_count of 1" do
      assert_equal 1, @place.locations_count
    end
    
    context "then remove a location" do
      setup do
        @place.locations.clear
        @place.reload
      end
      
      should_not_change "Place.count"
      should_not_change "Location.count"

      should "have no locations" do
        assert_equal [], @place.locations
      end

      should "have locations_count of 0" do
        assert_equal 0, @place.locations_count
      end
    end
    
    context "then add a location" do
      setup do
        @location2  = Location.create(:name => "Work")
        @place.locations.push(@location2)
        @place.reload
      end
    
      should_not_change "Place.count"
      should_change "Location.count", :by => 1
    
      should "have 2 locations" do
        assert_equal [@location, @location2], @place.locations
      end

      should "have locations_count of 2" do
        assert_equal 2, @place.locations_count
      end
    end
  end
end