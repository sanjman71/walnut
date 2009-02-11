require 'test/test_helper'
require 'test/factories'

class PlaceTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  should_have_many            :addresses
  should_belong_to            :chain
  
  context "create place with an address" do
    setup do
      @place    = Place.create(:name => "Place 1")
      @address  = Address.create(:name => "Home")
      @place.addresses.push(@address)
      @place.reload
    end
    
    should_change "Place.count", :by => 1
    should_change "Address.count", :by => 1
    
    should "have 1 address" do
      assert_equal [@address], @place.addresses
    end
    
    should "have addresses_count of 1" do
      assert_equal 1, @place.addresses_count
    end
    
    context "then remove an address" do
      setup do
        @place.addresses.clear
        @place.reload
      end
      
      should_not_change "Place.count"
      should_not_change "Address.count"

      should "have no address" do
        assert_equal [], @place.addresses
      end

      should "have addresses_count of 0" do
        assert_equal 0, @place.addresses_count
      end
    end
    
    context "then add an address" do
      setup do
        @address2  = Address.create(:name => "Work")
        @place.addresses.push(@address2)
        @place.reload
      end
    
      should_not_change "Place.count"
      should_change "Address.count", :by => 1
    
      should "have 2 address" do
        assert_equal [@address, @address2], @place.addresses
      end

      should "have addresses_count of 2" do
        assert_equal 2, @place.addresses_count
      end
    end
  end
end