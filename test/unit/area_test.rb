require 'test/test_helper'
require 'test/factories'

class AreaTest < ActiveSupport::TestCase
  
  def setup
    @us = Factory(:us)
  end
  
  context "create state area" do
    setup do
      @il   = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
      @area = Area.create(:extent => @il)
    end

    should_change "Area.count", :by => 1
        
    should "have area extent == state" do
      assert_equal @il, @area.extent
    end

    context "create city area" do
      setup do 
        @chicago  = Factory(:city, :name => "Chicago", :state => @il)
        @area2    = Area.create(:extent => @chicago)
      end

      should_change "Area.count", :by => 1

      should "have area extent == city" do
        assert_equal @chicago, @area2.extent
      end
      
      context "try to create duplicate city area" do
        setup do
          @area3 = Area.create(:extent => @chicago)
        end

        should_not_change "Area.count"
      end
      
    end
  end
  
  context "resolve country" do
    context "geocode united states" do
      setup do
        @object = Area.resolve("united states")
      end
      
      should "resolve to us country object" do
        assert_equal @us, @object
      end
    end

    context "geocode us" do
      setup do
        @object = Area.resolve("united states")
      end
      
      should "resolve to us country object" do
        assert_equal @us, @object
      end
    end
  end
  
  context "resolve state" do
    context "geocode illinois" do
      setup do
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @object = Area.resolve("illinois")
      end

      should "resolve to illinois state object" do
        assert_equal @il, @object
      end
    end
  end

  context "resolve city" do
    context "geocode chicago" do
      setup do
        @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @chicago  = Factory(:city, :name => "Chicago", :state => @il)
        @object   = Area.resolve("chicago")
      end

      should "resolve to chicago city object" do
        assert_equal @chicago, @object
      end
    end
  end
  
end
