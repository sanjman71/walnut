require 'test/test_helper'
require 'test/factories'

class AreaTest < ActiveSupport::TestCase
  
  def setup
    @us = Factory(:us)
  end
  
  context "state area" do
    setup do
      @il   = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
      @area = Area.create(:extent => @il)
    end

    should_change "Area.count", :by => 1
        
    should "have area extent illinois" do
      assert_equal @il, @area.extent
    end

    context "city area" do
      setup do 
        @chicago  = Factory(:city, :name => "Chicago", :state => @il)
        @area2    = Area.create(:extent => @chicago)
      end

      should_change "Area.count", :by => 1

      should "have area extent chicago" do
        assert_equal @chicago, @area2.extent
      end
      
      context "duplicate city area" do
        setup do
          @area3 = Area.create(:extent => @chicago)
        end

        should_not_change "Area.count"
      end
      
    end
  end
  
  context "geocode country" do
    context "united states" do
      setup do
        @object = Area.resolve("united states")
      end
      
      should "resolve to us country object" do
        assert_equal @us, @object
      end
    end

    context "us" do
      setup do
        @object = Area.resolve("united states")
      end
      
      should "resolve to us country object" do
        assert_equal @us, @object
      end
    end
  end
  
  context "geocode state" do
    context "illinois" do
      setup do
        @il     = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @object = Area.resolve("illinois")
      end

      should "resolve to illinois state object" do
        assert_equal @il, @object
      end
    end
  end

  context "geocode city" do
    context "chicago" do
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

  context "geocode zip" do
    context "60654" do
      setup do
        @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @zip      = Factory(:zip, :name => "60654", :state => @il)
        @object   = Area.resolve("60654")
      end

      should "resolve to chicago zip object" do
        assert_equal @zip, @object
      end
    end
  end
  
end
