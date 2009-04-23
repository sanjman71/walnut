require 'test/test_helper'
require 'test/factories'

class StreetAddressTest < ActiveSupport::TestCase

  context "normalize street address" do
    context "with 'West' predirectional" do
      setup do
        @address = "200 West Grand Ave"
      end
      
      should "change predirection to 'W'" do
        assert_equal "200 W Grand Ave", StreetAddress.normalize(@address)
      end
    end

    context "with 'Avenue' street type" do
      setup do
        @address = "200 W Grand Avenue"
      end
      
      should "change stree type to 'Ave'" do
        assert_equal "200 W Grand Ave", StreetAddress.normalize(@address)
      end
    end
  end
  
  context "get street address components" do
    context "for a basic address" do
      setup do
        @address = "200 W Grand Ave"
      end
      
      should "have components" do
        assert_equal Hash[:housenumber => "200", :predirectional => "W", :streetname => "Grand", :streettype => "Ave"], 
                     StreetAddress.components(@address) 
      end
    end
    
    context "for an address with a suite number" do
      setup do
        @address = "200 W Grand Ave # 2103"
      end

      should "have a suite number" do
        assert_equal Hash[:housenumber => "200", :predirectional => "W", :streetname => "Grand", :streettype => "Ave", :apttype => "Ste", :aptnumber => "2103"], 
                     StreetAddress.components(@address) 
      end
    end

    context "for an address with no predirectional" do
      setup do
        @address = "200 State St"
      end
      
      should "have no predirectional" do
        assert_equal Hash[:housenumber => "200", :streetname => "State", :streettype => "St"], 
                     StreetAddress.components(@address) 
      end
    end
    
    context "for an address with a pre and post directional and 2 word street name" do
      setup do
        @address = "322 West Armitage Park West"
      end
      
      should "have correct street name with pre and post directional" do
        assert_equal Hash[:housenumber => "322", :streetname => "Armitage Park", :predirectional => "W", :postdirectional => "W"], 
                     StreetAddress.components(@address) 
      end
    end
  end
end