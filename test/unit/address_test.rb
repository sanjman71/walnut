require 'test/test_helper'
require 'test/factories'

class AddressTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  
  def setup
    @il           = Factory(:state, :name => "Illinois", :ab => "IL")
    @chicago      = Factory(:city, :name => "Chicago", :state => @il)
    @area_il      = Area.create(:extent => @il)
    @area_chicago = Area.create(:extent => @chicago)
  end
  
  context "create address with 2 areas" do
    setup do
      @address = Address.create(:name => "Location 1")
      @address.areas.push(@area_il)
      @address.areas.push(@area_chicago)
      @address.reload
    end
    
    should_change "Address.count", :by => 1
    
    should "have 2 areas" do
      assert_equal [@area_il, @area_chicago], @address.areas
    end

    should "have 2 area tags" do
      assert_same_elements ["Chicago", "Illinois"], @address.area_tag_list
    end
    
    context "remove area" do
      setup do
        @address.areas.delete(@area_il)
        @address.save
        @address.reload
      end

      should "have 2 areas" do
        assert_equal [@area_chicago], @address.areas
      end

      should "have 1 area tag" do
        assert_same_elements ["Chicago"], @address.area_tag_list
      end
    end
  end
end
