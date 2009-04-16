require 'test/test_helper'
require 'test/factories'

class SearchTest < ActiveSupport::TestCase
  
  context "search localities" do
    context "with state and no 'what'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @search = Search.parse([@us, @il])
      end
      
      should "have localities tag and hash" do
        assert_equal ["United States", "Illinois"], @search.locality_tags
        assert_equal "United States Illinois", @search.field(:locality_tags)
        assert_equal Hash['country_id' => @us.id, 'state_id' => @il.id], @search.field(:locality_hash)
      end
      
      should "have no place tags" do
        assert_equal [], @search.place_tags
        assert_equal "", @search.field(:place_tags)
      end
      
      should "have no multiple field tags on name and place_tags" do
        assert_equal "", @search.multiple_fields(:name, :place_tags)
      end
    end
    
    context "with state, city, neighborhood and no 'what'" do
      setup do
        @us           = Factory.create(:us)
        @il           = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @chicago      = Factory(:city, :name => "Chicago", :state => @il)
        @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
        @search       = Search.parse([@us, @il, @chicago, @river_north])
      end

      should "have localities tag and hash" do
        assert_equal ["United States", "Illinois", "Chicago", "River North"], @search.locality_tags
        assert_equal "United States Illinois Chicago River North", @search.field(:locality_tags)
        assert_equal Hash['country_id' => @us.id, 'state_id' => @il.id, 'city_id' => @chicago.id, 'neighborhood_ids' => @river_north.id], 
                     @search.field(:locality_hash)
      end

      should "have no place tags" do
        assert_equal [], @search.place_tags
        assert_equal "", @search.field(:place_tags)
      end
    end
    
    context "with what 'coffee shop'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @search = Search.parse([@us, @il], "coffee shop")
      end
      
      should "have localities tag and hash" do
        assert_equal ["United States", "Illinois"], @search.locality_tags
        assert_equal "United States Illinois", @search.field(:locality_tags)
        assert_equal Hash['country_id' => @us.id, 'state_id' => @il.id], @search.field(:locality_hash)
      end
      
      should "have place tags" do
        assert_equal ["coffee", "shop"], @search.place_tags
        assert_equal "coffee | shop", @search.field(:place_tags)
      end
      
      should "have multiple field tags on name and place_tags" do
        assert_equal "@(name,place_tags) coffee | shop", @search.multiple_fields(:name, :place_tags)
      end

      should "have multiple field tags on place_tags" do
        assert_equal "@(place_tags) coffee | shop", @search.multiple_fields(:place_tags)
      end
    end
    
    context "with what 'anything'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @search = Search.parse([@us, @il], "anything")
      end
    
      should "have localities tag and hash" do
        assert_equal ["United States", "Illinois"], @search.locality_tags
        assert_equal "United States Illinois", @search.field(:locality_tags)
        assert_equal Hash['country_id' => @us.id, 'state_id' => @il.id], @search.field(:locality_hash)
      end
      
      should "have no place tags" do
        assert_equal [], @search.place_tags
        assert_equal '', @search.field(:place_tags)
      end
    
      should "have no field tags on name and place_tags" do
        assert_equal "", @search.multiple_fields(:name, :place_tags)
      end
    end
  end
end