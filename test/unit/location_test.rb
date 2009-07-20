require 'test/test_helper'
require 'test/factories'

class LocationTest < ActiveSupport::TestCase
  
  should_belong_to    :country
  should_belong_to    :state
  should_belong_to    :city
  should_belong_to    :zip
  should_belong_to    :timezone
  should_have_many    :neighborhoods
  should_have_many    :companies
  should_have_many    :phone_numbers
  should_have_many    :neighbors
  should_have_many    :sources
  
  def setup
    @us           = Factory(:us)
    @canada       = Factory(:canada)
    @il           = Factory(:il, :country => @us)
    @on           = Factory(:ontario, :country => @canada)
    @chicago      = Factory(:chicago, :state => @il, :timezone => Factory(:timezone_chicago))
    @toronto      = Factory(:toronto, :state => @on)
    @zip          = Factory(:zip, :name => "60654", :state => @il)
    @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
    @company      = Company.create(:name => "My Company", :time_zone => "UTC")
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
      @location = Location.create(:name => "Home", :state => @il, :country => @us)
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
        @location.country = @canada
        @location.save
        @on.reload
        @il.reload
        @us.reload
        @canada.reload
      end
      
      should "change country to new state's country" do
        assert_equal @on.country, @location.country
      end
      
      should "decrement illinois locations_count" do
        assert_equal 0, @il.locations_count
      end

      should "decrement us locations_count" do
        assert_equal 0, @us.locations_count
      end
      
      should "increment ontario locations_count" do
        assert_equal 1, @on.locations_count
      end

      should "increment canada locations_count" do
        assert_equal 1, @canada.locations_count
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
  
  context "location with a company and city" do
    setup do
      @location = Location.create(:name => "Home", :city => @chicago, :country => @us)
      @company.locations.push(@location)
      @company.reload
      @location.reload
      @chicago.reload
      @us.reload
    end
    
    should_change "Location.count", :by => 1
    should_change "CompanyLocation.count", :by => 1

    should "increment chicago locations_count" do
      assert_equal 1, @chicago.locations_count
    end

    should "increment us locations_count" do
      assert_equal 1, @us.locations_count
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
        @location.state = @on
        @location.country = @canada
        @location.save
        @chicago.reload
        @us.reload
        @toronto.reload
        @on.reload
        @canada.reload
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
      
      should "decrement chicago locations_count" do
        assert_equal 0, @chicago.locations_count
      end

      should "decrement illinois locations_count" do
        assert_equal 0, @il.locations_count
      end

      should "decrement us locations_count" do
        assert_equal 0, @us.locations_count
      end

      should "increment toronto locations_count" do
        assert_equal 1, @toronto.locations_count
      end

      should "increment ontario locations_count" do
        assert_equal 1, @on.locations_count
      end

      should "increment canada locations_count" do
        assert_equal 1, @canada.locations_count
      end
      
      # TODO: We should check the neighborhoods on a location when we change the location's city etc.
      # should "clear all existing neighborhoods not in the new city" do
      #   assert_equal @location.neighborhoods, []
      # end
      
    end
    
    context "remove company" do
      setup do
        @company.locations.delete(@location)
      end

      should_change "CompanyLocation.count", :by => -1
      
      should "leave chicago locations as [@location]" do
        assert_equal [@location], @chicago.locations
      end

      should "have no companies associated with location" do
        assert_equal [], @location.companies
      end
    end
  end

  # context "location with city and state" do
  #   setup do
  #     @location = Location.create(:city => @chicago, :state => @il, :country => @us)
  #   end
  # 
  #   should_change "Location.count", :by => 1
  # 
  #   should "increment city locations_count" do
  #     assert_equal 1, @chicago.reload.locations_count
  #   end
  # 
  #   should "increment state locations_count" do
  #     assert_equal 1, @il.reload.locations_count
  #   end
  # 
  #   should "increment country locations_count" do
  #     assert_equal 1, @us.reload.locations_count
  #   end
  # end
  
  context "location with a company and zip" do
    setup do
      @location = Location.create(:name => "Home", :zip => @zip, :country => @us)
      @company.locations.push(@location)
      @zip.reload
      @il.reload
      @us.reload
    end
    
    should_change "Location.count", :by => 1
    should_change "CompanyLocation.count", :by => 1

    should "increment zip locations_count" do
      assert_equal 1, @zip.locations_count
    end

    should "set zip locations to [@location]" do
      assert_equal [@location], @zip.locations
    end

    should "increment us locations_count" do
      assert_equal 1, @us.locations_count
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
  
  context "location with a company and neighborhood" do
    setup do
      @location = Location.create(:name => "Home", :country => @us)
      @location.neighborhoods.push(@river_north)
      @location.reload
      @company.locations.push(@location)
      @location.reload
      @river_north.reload
    end
    
    should_change "Location.count", :by => 1
    should_change "CompanyLocation.count", :by => 1
  
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

    should "assign neighborhood's city, state and country" do
      assert_equal @location.city, @river_north.city
      assert_equal @location.state, @river_north.city.state
      assert_equal @location.country, @river_north.city.state.country
    end
    
    should "increment city.locations_count" do
      assert_equal 1, @location.city.locations_count
    end

    should "increment state.locations_count" do
      assert_equal 1, @location.state.locations_count
    end

    should "increment country.locations_count" do
      assert_equal 1, @location.country.locations_count
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
  
  context "location timezone" do
    context "where location timezone is set" do
      setup do
        @timezone  = Factory(:timezone, :name => "America/New_York")
        @location  = Location.create(:country => @us, :state => @illinois, :city => @chicago, :timezone => @timezone)
      end

      should "use location's timezone" do
        assert_equal @timezone, @location.timezone
      end
    end

    context "where location timezone is empty" do
      setup do
        @location  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
      end

      should "use city's timezone" do
        assert_equal @chicago.timezone, @location.timezone
      end
    end
    
    context "where location city is empty" do
      setup do
        @location  = Location.create(:country => @us, :state => @illinois)
      end

      should "have no timezone" do
        assert_equal nil, @location.timezone
      end
    end
  end

  context "merge locations" do
    setup do
      @location1  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
      @location1.phone_numbers.push(PhoneNumber.new(:name => "Work", :number => "1111111111"))
      @location1.location_sources.push(LocationSource.new(:location => @location1, :source_id => 1, :source_type => "Test"))
      @company1   = Company.create(:name => "Walnut Industries Chicago", :time_zone => "UTC")
      @company1.locations.push(@location1)
      @location1.reload
      @company1.tag_list.add("tag1")
      @company1.save
      
      @location2  = Location.create(:country => @us, :state => @illinois, :city => @chicago)
      @location2.phone_numbers.push(PhoneNumber.new(:name => "Work", :number => "2222222222"))
      @location2.location_sources.push(LocationSource.new(:location => @location2, :source_id => 2, :source_type => "Test"))
      @company2   = Company.create(:name => "Walnut Industries San Francisco", :time_zone => "UTC")
      @company2.locations.push(@location2)
      @location2.reload
      @company2.tag_list.add("tag2")
      @company2.save
    end
    
    should_change "Location.count", :by => 2
    should_change "Company.count", :by => 2
    should_change "PhoneNumber.count", :by => 2
    should_change "LocationSource.count", :by => 2
    
    context "and then merge locations" do
      setup do
        LocationHelper.merge_locations([@location1, @location2])
        @location1.reload
      end
      
      should_change "Location.count", :by => -1
      should_change "Company.count", :by => -1
      should_not_change "PhoneNumber.count"
      should_not_change "LocationSource.count"
      
      should "add tags to location1" do
        assert_equal ["tag1", "tag2"], @location1.company.tag_list
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
      
      should "remove company2" do
        assert_equal nil, Company.find_by_id(@company2.id)
      end
      
      should "remove location1" do
        assert_equal nil, Location.find_by_id(@location2.id)
      end
    end
  end
  
end
