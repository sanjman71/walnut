require 'test/test_helper'
require 'test/factories'

class AddressTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  
  def setup
    @us           = Factory(:us)
    @il           = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago      = Factory(:city, :name => "Chicago", :state => @il)
    @area_us      = Area.create(:extent => @us)
    @area_il      = Area.create(:extent => @il)
    @area_chicago = Area.create(:extent => @chicago)
  end
  
  context "create address with 3 areas" do
    setup do
      @address = Address.create(:name => "Location 1")
      @address.areas.push(@area_us)
      @address.areas.push(@area_il)
      @address.areas.push(@area_chicago)
      @address.reload
    end
    
    should_change "Address.count", :by => 1
    
    should "have 3 areas" do
      assert_equal [@area_us, @area_il, @area_chicago], @address.areas
    end

    should "have 3 area tags" do
      assert_same_elements ["Chicago", "Illinois", "United States"], @address.area_tag_list
    end
    
    context "then remove an area" do
      setup do
        @address.areas.delete(@area_chicago)
        @address.save
        @address.reload
      end

      should "have 2 areas" do
        assert_same_elements [@area_il, @area_us], @address.areas
      end

      should "have 2 area tags" do
        assert_same_elements ["Illinois", "United States"], @address.area_tag_list
      end
    end
  end
end
