require 'test/test_helper'
require 'test/factories'

class SearchTest < ActiveSupport::TestCase
  
  context "search localities" do
    context "with no tags" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @search = Search.parse([@us, @il])
      end
      
      should "have localities tag" do
        assert_equal ["United States", "Illinois"], @search.locality_tags
        assert_equal "United States Illinois", @search.field_for(:locality_tags)
      end
      
      should "have no place tags" do
        assert_equal [], @search.place_tags
        assert_equal "", @search.field_for(:place_tags)
      end
    end
    
    context "with tags 'coffee shop'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @search = Search.parse([@us, @il], "coffee shop")
      end
      
      should "have localities tag" do
        assert_equal ["United States", "Illinois"], @search.locality_tags
        assert_equal "United States Illinois", @search.field_for(:locality_tags)
      end
      
      should "have place tags" do
        assert_equal ["coffee", "shop"], @search.place_tags
        assert_equal "coffee || shop", @search.field_for(:place_tags)
      end
    end
    
  end
end