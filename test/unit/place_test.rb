require 'test/test_helper'
require 'test/factories'

class PlaceTest < ActiveSupport::TestCase
  
  should_validate_presence_of :name
  should_have_many            :locations
  should_have_many            :phone_numbers
  should_have_many            :place_tag_groups
  should_have_many            :tag_groups
  should_belong_to            :chain
  
  context "create place with a location" do
    setup do
      @us       = Factory(:us)
      @il       = Factory(:il, :country_id => @us.id)
      @chicago  = Factory(:chicago, :state_id => @il.id)
      
      @canada   = Factory(:canada)
      @ontario  = Factory(:ontario, :country_id => @canada.id)
      @toronto  = Factory(:toronto, :state_id => @ontario.id)
      
      @place    = Place.create(:name => "Place 1")
      @location = Location.create(:name => "Home", :city => @chicago)
      @place.locations.push(@location)
      @place.reload
    end
    
    should_change "Place.count", :by => 1
    should_change "Location.count", :by => 1
    
    should "have 1 location" do
      assert_equal [@location], @place.locations
    end
    
    should "have locations_count of 1" do
      assert_equal 1, @place.locations_count
    end
    
    should "not belong to chain" do
      assert_equal false, @place.chain?
    end
    
    context "then remove location" do
      setup do
        @place.locations.delete(@location)
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
        @location2  = Location.create(:city => @toronto)
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
  
  context "place with a phone number" do
    setup do
      @place  = Place.create(:name => "Place 1")
      @place.phone_numbers.push(PhoneNumber.new(:name => "Home", :number => "9991234567"))
      @place.reload
    end
  
    should_change "Place.count", :by => 1
    should_change "PhoneNumber.count", :by => 1
    
    should "have 1 phone number" do
      assert_equal ["9991234567"], @place.phone_numbers.collect(&:number)
    end
    
    should "have phone_numbers_count == 1" do
      assert_equal 1, @place.phone_numbers_count
    end

    should "have a primary phone number" do
      assert_equal "9991234567", @place.primary_phone_number.number
    end
  end
  
  context "place with tags" do
    setup do
      @place = Place.create(:name => "Place 1")
      @place.tag_list.add(["pizza","soccer"])
      @place.save
      @place.reload
    end
    
    should_change "Place.count", :by => 1
    should_change "Tag.count", :by => 2
    should_change "Tagging.count", :by => 2
    
    should "set tag.taggings_count to 1" do
      assert_equal 1, Tag.find_by_name("pizza").taggings.count
      assert_equal 1, Tag.find_by_name("soccer").taggings.count
    end
    
    should "increment place.taggings_count to 2" do
      assert_equal 2, @place.taggings_count
    end

    context "then remove a tag" do
      setup do
        @place.tag_list.remove("pizza")
        @place.save
        @place.reload
      end

      should_change "Tagging.count", :by => -1
      
      should "descrement tag.taggings_count to 0" do
        assert_equal 0, Tag.find_by_name("pizza").taggings.count
      end

      should "decrement place.taggings_count to 1" do
        assert_equal 1, @place.taggings_count
      end
    end
    
    context "then add another tag" do
      setup do
        @place.tag_list.add("beer")
        @place.save
        @place.reload 
      end

      should_change "Tag.count", :by => 1
      should_change "Tagging.count", :by => 1

      should "set tag.taggings_count to 1" do
        assert_equal 1, Tag.find_by_name("beer").taggings.count
      end

      should "increment place.taggings_count to 3" do
        assert_equal 3, @place.taggings_count
      end
    end
  end
end