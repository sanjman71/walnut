require 'test/test_helper'
require 'test/factories'

class PlaceTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  
  def setup
    # @il           = Factory(:state, :name => "Illinois", :ab => "IL")
    # @chicago      = Factory(:city, :name => "Chicago", :state => @il)
    # @area_il      = Area.create(:extent => @il)
    # @area_chicago = Area.create(:extent => @chicago)
  end
  
  context "create place with an address" do
    setup do
      @place    = Place.create(:name => "Place 1")
      @address  = Address.create(:name => "Home")
      @place.addresses.push(@address)
      @place.reload
    end
    
    should_change "Place.count", :by => 1
    
    should "have 1 address" do
      assert_equal [@address], @place.addresses
      assert_equal [@place], @address.addressables
    end
  end
end