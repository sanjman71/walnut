require 'test/test_helper'
require 'test/factories'

class AddressTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  should_belong_to            :country
  
  def setup
    @us           = Factory(:us)
    @ca           = Factory(:country, :name => "Canada", :code => "CA")
    @il           = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago      = Factory(:city, :name => "Chicago", :state => @il)
    @zip          = Factory(:zip, :name => "60654", :state => @il)
    @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
    @area_us      = Area.create(:extent => @us)
    @area_ca      = Area.create(:extent => @ca)
    @area_il      = Area.create(:extent => @il)
    @area_chicago = Area.create(:extent => @chicago)
    @area_zip     = Area.create(:extent => @zip)
    @area_hood    = Area.create(:extent => @river_north)
  end

  context "address with country" do
    setup do
      @address = Address.create(:name => "Home", :country => @us)
    end
    
    should_change "Address.count", :by => 1
    should_change "AddressArea.count", :by => 1
    
    should "have us country area" do
      assert_equal [@area_us], @address.areas
    end

    should "have us country area tag" do
      assert_equal ["United States"], @address.area_tag_list
    end

    context "remove country" do
      setup do
        @address.country = nil
        @address.save
      end

      should_change "AddressArea.count", :by => -1

      should "have no areas" do
        assert_equal [], @address.areas
      end
      
      should "have no area tags" do
        assert_equal [], @address.area_tag_list
      end
    end
    
    context "change country" do
      setup do
        @address.country = @ca
        @address.save
      end

      should_not_change "AddressArea.count"

      should "have ca country area" do
        assert_equal [@area_ca], @address.areas
      end
      
      should "have ca country area tag" do
        assert_equal ["Canada"], @address.area_tag_list
      end
    end
  end
  
  context "address with state" do
    setup do
      @address = Address.create(:name => "Home", :state => @il)
    end
    
    should_change "Address.count", :by => 1
    should_change "AddressArea.count", :by => 1
    
    should "have illinois area" do
      assert_equal [@area_il], @address.areas
    end
    
    should "have illinois area tag" do
      assert_equal ["Illinois"], @address.area_tag_list
    end
    
    context "remove state" do
      setup do
        @address.state = nil
        @address.save
      end

      should_change "AddressArea.count", :by => -1

      should "have no areas" do
        assert_equal [], @address.areas
      end
    end
  end

  context "address with city" do
    setup do
      @address = Address.create(:name => "Home", :city => @chicago)
    end
    
    should_change "Address.count", :by => 1
    should_change "AddressArea.count", :by => 1
    
    should "have chicago area" do
      assert_equal [@area_chicago], @address.areas
    end

    should "have chicago area tag" do
      assert_equal ["Chicago"], @address.area_tag_list
    end
    
    context "remove city" do
      setup do
        @address.city = nil
        @address.save
      end

      should_change "AddressArea.count", :by => -1

      should "have no areas" do
        assert_equal [], @address.areas
      end

      should "have no area tags" do
        assert_equal [], @address.area_tag_list
      end
    end
  end

  context "address with zip" do
    setup do
      @address = Address.create(:name => "Home", :zip => @zip)
    end
    
    should_change "Address.count", :by => 1
    should_change "AddressArea.count", :by => 1
    
    should "have 60654 area" do
      assert_equal [@area_zip], @address.areas
    end

    should "have 60654 area tag" do
      assert_equal ["60654"], @address.area_tag_list
    end
    
    context "remove zip" do
      setup do
        @address.zip = nil
        @address.save
      end

      should_change "AddressArea.count", :by => -1

      should "have no areas" do
        assert_equal [], @address.areas
      end

      should "have no area tags" do
        assert_equal [], @address.area_tag_list
      end
    end
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

    context "with zip area removed" do
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
      
      should "have empty zip" do
        assert_equal nil, @address.zip
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
