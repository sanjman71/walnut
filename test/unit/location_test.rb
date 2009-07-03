require 'test/test_helper'
require 'test/factories'

class LocationTest < ActiveSupport::TestCase
  
  should_belong_to    :country
  should_belong_to    :state
  should_belong_to    :city
  should_belong_to    :zip
  should_have_many    :neighborhoods
  should_have_many    :places
  should_have_many    :phone_numbers
  should_have_many    :neighbors
  should_have_many    :sources
  
  def setup
    @us           = Factory(:us)
    @canada       = Factory(:canada)
    @il           = Factory(:il, :country => @us)
    @on           = Factory(:ontario, :country => @canada)
    @chicago      = Factory(:chicago, :state => @il)
    @toronto      = Factory(:toronto, :state => @on)
    @zip          = Factory(:zip, :name => "60654", :state => @il)
    @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
    @place        = Place.create(:name => "My Place")
  end

  context "location with country" do
    setup do
      @location = Location.create(:country => @us)
      @us.reload
    end
    
    should_change "Location.count", :by => 1
    
    should "have us as locality" do
      assert_equal [@us], @location.localities
    end

    should "increment us locations_count" do
      assert_equal 1, @us.locations_count
    end

    should "have refer_to? == false" do
      assert_equal false, @location.refer_to?
    end
    
    context "change country" do
      setup do
        @location.country = @canada
        @location.save
        @us.reload
        @canada.reload
      end
    
      should "decrement us locations_count" do
        assert_equal 0, @us.locations_count
      end

      should "increment canada locations_count" do
        assert_equal 1, @canada.locations_count
      end
    end
  end
  
  context "location with state" do
    setup do
      @location = Location.create(:name => "Home", :state => @il)
      @il.reload
    end
    
    should_change "Location.count", :by => 1

    should "have state's country" do
      assert_equal @location.country, @il.country
    end

    should "increment illinois locations_count" do
      assert_equal 1, @il.locations_count
    end
    
    context "change state" do
      setup do
        @location.state = @on
        @location.save
        @on.reload
        @il.reload
      end
      
      should "change country to new state's country" do
        assert_equal @on.country, @location.country
      end
      
      should "decrement old state's locations_count" do
        assert_equal 0, @il.locations_count
      end
      
      should "increment new state's locations_count" do
        assert_equal 1, @on.locations_count
      end
    end
    
    context "remove state" do
      setup do
        @location.state = nil
        @location.save
        @il.reload
      end

      should "decrement illinois locations_count" do
        assert_equal 0, @il.locations_count
      end
    end
  end
  
  context "location with a place and city" do
    setup do
      @location = Location.create(:name => "Home", :city => @chicago)
      @place.locations.push(@location)
      @place.reload
      @location.reload
      @chicago.reload
    end
    
    should_change "Location.count", :by => 1
    should_change "LocationPlace.count", :by => 1

    should "have city's state & country" do
      assert_equal @location.state, @chicago.state
      assert_equal @location.country, @chicago.state.country
    end

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
      end

      should "decrement chicago locations_count" do
        assert_equal 0, @chicago.locations_count
      end

      should "set chicago locations to []" do
        assert_equal [], @chicago.locations
      end
    end
    
    context "change city" do
      setup do
        @location.city = @toronto
        @location.save
        @chicago.reload
        @toronto.reload
      end

      should "remove chicago locations" do
        assert_equal [], @chicago.locations
      end

      should "set toronto locations to [@location]" do
        assert_equal [@location], @toronto.locations
      end

      should "set location's state and country to new city's state and country" do
        assert_equal @toronto.state, @location.state
        assert_equal @toronto.state.country, @location.country
      end
      
      # TODO: We should check the neighborhoods on a location when we change the location's city etc.
      # should "clear all existing neighborhoods not in the new city" do
      #   assert_equal @location.neighborhoods, []
      # end
      
    end
    
    context "remove place" do
      setup do
        @place.locations.delete(@location)
      end

      should_change "LocationPlace.count", :by => -1
      
      should "leave chicago locations as [@location]" do
        assert_equal [@location], @chicago.locations
      end

      should "have no places associated with location" do
        assert_equal [], @location.places
      end
    end
  end

  context "location with a place and zip" do
    setup do
      @location = Location.create(:name => "Home", :zip => @zip)
      @place.locations.push(@location)
      @zip.reload
    end
    
    should_change "Location.count", :by => 1
    should_change "LocationPlace.count", :by => 1

    should "have zip's state & country" do
      assert_equal @location.state, @zip.state
      assert_equal @location.country, @zip.state.country
    end

    should "increment zip locations_count" do
      assert_equal 1, @zip.locations_count
    end

    should "set zip locations to [@location]" do
      assert_equal [@location], @zip.locations
    end
    
    context "remove zip" do
      setup do
        @location.zip = nil
        @location.save
        @zip.reload
      end

      should "decrement zip locations_count" do
        assert_equal 0, @zip.locations_count
      end

      should "remove zip locations" do
        assert_equal [], @zip.locations
      end
    end
    
    context "change zip" do
      setup do
        @zip2 = Factory(:zip, :name => "60610", :state => @il)
        @location.zip = @zip2
        @location.save
        @zip2.reload
        @zip.reload
      end

      should "set 60654 locations to []" do
        assert_equal [], @zip.locations
      end
      
      should "set 60610 locations to [@location]" do
        assert_equal [@location], @zip2.locations
      end
    end
  end
  
  context "location with a place and neighborhood" do
    setup do
      @location = Location.new(:name => "Home")
      @location.neighborhoods.push(@river_north)
      @location.save
      @place.locations.push(@location)
      @location.reload
      @river_north.reload
    end
    
    should_change "Location.count", :by => 1
    should_change "LocationPlace.count", :by => 1
  
    should "have neighborhood's city, state and country" do
      assert_equal @location.city, @river_north.city
      assert_equal @location.state, @river_north.city.state
      assert_equal @location.country, @river_north.city.state.country
    end

    should "have neighborhood locality" do
      assert_contains @location.localities, @river_north
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
  
  context "location with a phone number" do
    setup do
      @location = Location.create(:name => "My Location", :country => @us)
      @location.phone_numbers.push(PhoneNumber.new(:name => "Home", :number => "9991234567"))
      @location.reload
    end
  
    should_change "Location.count", :by => 1
    should_change "PhoneNumber.count", :by => 1
    
    should "have 1 phone number" do
      assert_equal ["9991234567"], @location.phone_numbers.collect(&:number)
    end
    
    should "have phone_numbers_count == 1" do
      assert_equal 1, @location.phone_numbers_count
    end
    
    should "have a primary phone number" do
      assert_equal "9991234567", @location.primary_phone_number.number
    end
    
    context "then destroy phone number" do
      setup do
        @phone_number = @location.phone_numbers.first
        @location.phone_numbers.destroy(@phone_number)
        @location.reload
      end
      
      should_change "PhoneNumber.count", :by => -1

      should "have no phone number" do
        assert_equal [], @location.phone_numbers
      end

      should "have phone_numbers_count == 0" do
        assert_equal 0, @location.phone_numbers_count
      end
    end
  end
  
  context "location without refer_to" do
    setup do
      @location = Location.create(:name => "Home", :country => @us)
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
  
  context "create 2 locations" do
    setup do
      @location1  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
      @location1.phone_numbers.push(PhoneNumber.new(:name => "Work", :number => "1111111111"))
      @location1.location_sources.push(LocationSource.new(:location => @location1, :source_id => 1, :source_type => "Test"))
      @place1     = Place.create(:name => "Fun Place")
      @place1.locations.push(@location1)
      @location1.reload
      @place1.tag_list.add("tag1")
      @place1.save
      
      @location2  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
      @location2.phone_numbers.push(PhoneNumber.new(:name => "Work", :number => "2222222222"))
      @location2.location_sources.push(LocationSource.new(:location => @location2, :source_id => 2, :source_type => "Test"))
      @place2     = Place.create(:name => "Fun Place")
      @place2.locations.push(@location2)
      @location2.reload
      @place2.tag_list.add("tag2")
      @place2.save
    end
    
    should_change "Location.count", :by => 2
    should_change "Place.count", :by => 2
    should_change "PhoneNumber.count", :by => 2
    should_change "LocationSource.count", :by => 2
    
    context "and then merge locations" do
      setup do
        LocationHelper.merge_locations([@location1, @location2])
        @location1.reload
      end
      
      should_change "Location.count", :by => -1
      should_change "Place.count", :by => -1
      should_not_change "PhoneNumber.count"
      should_not_change "LocationSource.count"
      
      should "add tags to location1" do
        assert_equal ["tag1", "tag2"], @location1.place.tag_list
      end
      
      should "add phone number to location1" do
        assert_equal ["1111111111", "2222222222"], @location1.phone_numbers.collect(&:number)
      end
      
      should "have phone_numbers_count == 2" do
        assert_equal 2, @location1.phone_numbers_count
      end
      
      should "add location source to location1" do
        assert_equal [1, 2], @location1.location_sources.collect(&:source_id)
      end
      
      should "remove place2" do
        assert_equal nil, Place.find_by_id(@place2.id)
      end
      
      should "remove location1" do
        assert_equal nil, Location.find_by_id(@location2.id)
      end
    end
  end
  
end
