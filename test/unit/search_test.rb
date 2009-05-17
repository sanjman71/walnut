require 'test/test_helper'
require 'test/factories'

class SearchTest < ActiveSupport::TestCase
  
  context "search with" do
    setup do
      @us         = Factory.create(:us)
      @il         = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
      @chicago    = Factory(:city, :name => "Chicago", :state => @il)
      @attributes = Search.attributes(@il, @chicago, nil)
    end
    
    should "have hash attributes with :state_id" do
      assert_equal Hash[:state_id => @il.id, :city_id => @chicago.id], @attributes
    end
  end

  context "search query with a query string only" do
    setup do
      @hash = Search.query("hair salon")
    end
    
    should "have query" do
      assert_equal Hash[:query_raw => "hair salon", :query_and => "hair salon", :query_or => "hair | salon"], @hash
    end
  end

  context "search query with no query string and events attribute" do
    setup do
      @hash = Search.query("events:1")
    end
    
    should "have attributes hash" do
      assert_equal Hash[:query_raw => "events:1", :query_and => '', :query_or => '', :attributes => {:events => 1..2**30}], @hash
    end
  end

  context "search query with no query string and address field" do
    setup do
      @hash = Search.query("address:'200 grand'")
    end
    
    should "have fields hash" do
      assert_equal Hash[:query_raw => "address:'200 grand'", :query_and => '', :query_or => '', :fields => {:address => '200 grand'}], @hash
    end
  end
  
  context "search query with a query string and events attribute" do
    setup do
      @hash = Search.query("music events:1")
    end
    
    should "have attributes hash" do
      assert_equal Hash[:query_raw => "music events:1", :query_and => 'music', :query_or => 'music', :attributes => {:events => 1..2**30}], @hash
    end
  end

  context "search query with a query string and popularity attribute" do
    setup do
      @hash = Search.query("bar popularity:50")
    end
    
    should "have attributes hash" do
      assert_equal Hash[:query_raw => "bar popularity:50", :query_and => 'bar', :query_or => 'bar', :attributes => {:popularity => 50..2**30}], @hash
    end
  end

  context "search query with a query string and address field" do
    setup do
      @hash = Search.query("music address:'200 grand'")
    end
    
    should "have fields hash" do
      assert_equal Hash[:query_raw => "music address:'200 grand'", :query_and => 'music', :query_or => 'music', :fields => {:address => '200 grand'}], @hash
    end
  end

  context "search query with a query string, events attribute and address field" do
    setup do
      @hash = Search.query("music concerts events:1 address:'200 grand'")
    end
    
    should "have attributes and fields hash" do
      assert_equal Hash[:query_raw => "music concerts events:1 address:'200 grand'", :query_and => 'music concerts', :query_or => 'music | concerts',
                        :attributes => {:events => 1..2**30}, :fields => {:address => '200 grand'}], @hash
    end
  end
  
  context "search parse localities" do
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
      
      should "have empty query" do
        assert_equal "", @search.query
      end
      
      # should "have no multiple field tags on name and place_tags" do
      #   assert_equal "", @search.multiple_fields(:name, :place_tags)
      # end
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

      should "have empty query" do
        assert_equal "", @search.query
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
      
      should "have default query using 'or' operator" do
        assert_equal "coffee | shop", @search.query
      end

      should "have valid query using 'and' operator" do
        assert_equal "coffee shop", @search.query(:operator => :and)
      end
      
      # should "have multiple field tags on name and place_tags" do
      #   assert_equal "@(name,place_tags) coffee | shop", @search.multiple_fields(:name, :place_tags)
      # end

      # should "have multiple field tags on place_tags" do
      #   assert_equal "@(place_tags) coffee | shop", @search.multiple_fields(:place_tags)
      # end
    end
    
    context "with what 'schuba's'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @search = Search.parse([@us, @il], "schuba's")
      end

      should "have query with quote removed" do
        assert_equal "schubas", @search.query
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
      
      should "have empty query" do
        assert_equal "", @search.query
      end
    
      # should "have no field tags on name and place_tags" do
      #   assert_equal "", @search.multiple_fields(:name, :place_tags)
      # end
    end
  end
end