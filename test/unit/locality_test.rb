require 'test/test_helper'
require 'test/factories'

class LocalityTest < ActiveSupport::TestCase
  
  def setup
    @us = Factory(:us)
  end
  
  context "state locality" do
    setup do
      @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
      @locality = Locality.create(:extent => @il)
    end

    should_change "Locality.count", :by => 1
        
    should "have locality extent illinois" do
      assert_equal @il, @locality.extent
    end

    context "city area" do
      setup do 
        @chicago    = Factory(:city, :name => "Chicago", :state => @il)
        @locality2  = Locality.create(:extent => @chicago)
      end

      should_change "Locality.count", :by => 1

      should "have area extent chicago" do
        assert_equal @chicago, @locality2.extent
      end
      
      context "duplicate city area" do
        setup do
          @locality3 = Locality.create(:extent => @chicago)
        end

        should_not_change "Locality.count"
      end
      
    end
  end
  
  context "geocode country" do
    context "united states" do
      setup do
        @object = Locality.resolve("united states")
      end
      
      should "resolve to us country object" do
        assert_equal @us, @object
      end
    end

    context "us" do
      setup do
        @object = Locality.resolve("united states")
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
        @object = Locality.resolve("illinois")
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
        @object   = Locality.resolve("chicago")
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
        @object   = Locality.resolve("60654")
      end

      should "resolve to chicago zip object" do
        assert_equal @zip, @object
      end
    end
  end
  
end
