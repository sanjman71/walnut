require 'test/test_helper'
require 'test/factories'

class AddressTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  
  def setup
    @us           = Factory(:us)
    @il           = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago      = Factory(:city, :name => "Chicago", :state => @il)
    @zip          = Factory(:zip, :name => "60654", :state => @il)
    @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
    @area_us      = Area.create(:extent => @us)
    @area_il      = Area.create(:extent => @il)
    @area_chicago = Area.create(:extent => @chicago)
    @area_zip     = Area.create(:extent => @zip)
    @area_hood    = Area.create(:extent => @river_north)
  end
  
  context "address with 4 areas" do
    setup do
      @address = Address.create(:name => "Location 1")
      @address.areas.push(@area_us)
      @address.areas.push(@area_il)
      @address.areas.push(@area_chicago)
      @address.areas.push(@area_zip)
      @address.reload
    end
    
    should_change "Address.count", :by => 1
    
    should "have 4 areas" do
      assert_equal [@area_us, @area_il, @area_chicago, @area_zip], @address.areas
    end

    should "have 4 area tags" do
      assert_same_elements ["60654", "Chicago", "Illinois", "United States"], @address.area_tag_list
    end
    
    context "with 1 area removed" do
      setup do
        @address.areas.delete(@area_zip)
        @address.save
        @address.reload
      end

      should "have 3 areas" do
        assert_same_elements [@area_chicago, @area_il, @area_us], @address.areas
      end

      should "have 3 area tags" do
        assert_same_elements ["Chicago", "Illinois", "United States"], @address.area_tag_list
      end
      
      context "with neighborhood area added" do
        setup do
          @address.areas.push(@area_hood)
          @address.reload
        end
        
        should "have river north as an area" do
          assert_same_elements [@area_hood, @area_chicago, @area_il, @area_us], @address.areas
        end
        
        should "have river north area tag" do
          assert_same_elements ["River North", "Chicago", "Illinois", "United States"], @address.area_tag_list
        end
      end
    end
  end
end
