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

  context "search query with no query string and no events attribute" do
    setup do
      @hash = Search.query("events:0")
    end

    should "have attributes hash" do
      assert_equal Hash[:query_raw => "events:0", :query_and => '', :query_or => '', :attributes => {:events => 0}], @hash
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

  context "search query with no query string and address field with caps" do
    setup do
      @hash = Search.query("address:'200 Grand Ave'")
    end

    should "have fields hash" do
      assert_equal Hash[:query_raw => "address:'200 Grand Ave'", :query_and => '', :query_or => '', :fields => {:address => '200 Grand Ave'}], @hash
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
  
  context "search locality attributes" do
    context "with country and state" do
      setup do
        @us         = Factory.create(:us)
        @il         = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @attributes = Search.attributes(@us, @il)
      end
    
      should "have attributes hash with country and state" do
        assert_equal Hash[:country_id => @us.id, :state_id => @il.id], @attributes
      end
    end

    context "with country, state, city, neighborhood" do
      setup do
        @us           = Factory.create(:us)
        @il           = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @chicago      = Factory(:city, :name => "Chicago", :state => @il)
        @river_north  = Factory(:neighborhood, :name => "River North", :city => @chicago)
        @attributes   = Search.attributes(@us, @il, @chicago, @river_north)
      end

      should "have attributes hash with country and state" do
        assert_equal Hash[:country_id => @us.id, :state_id => @il.id, :city_id => @chicago.id, :neighborhood_ids => @river_north.id], @attributes
      end
    end
  end

  context "search parse query" do
    context "with query 'coffee shop'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @hash = Search.query("coffee shop")
      end
      
      should "have different 'or' and 'and' queries" do
        assert_equal "coffee | shop", @hash[:query_or]
        assert_equal "coffee shop", @hash[:query_and]
      end
    end

    context "with query 'schuba's'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @hash   = Search.query("schuba's")
      end

      should "have raw query with quote" do
        assert_equal "schuba's", @hash[:query_raw]
      end
      
      should "have query with quote removed" do
        assert_equal "schubas", @hash[:query_or]
      end
    end

    context "with query 'anything'" do
      setup do
        @us     = Factory.create(:us)
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @hash   = Search.query("anything")
      end
      
      should "have empty query" do
        assert_equal "", @hash[:query_or]
        assert_equal "", @hash[:query_and]
      end
      
      should "have raw query of 'anything'" do
        assert_equal "anything", @hash[:query_raw]
      end
    end
  end
end