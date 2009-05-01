require 'test/test_helper'
require 'test/factories'

class LocalityTest < ActiveSupport::TestCase
  
  def setup
    @us = Factory(:us)
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
    
    context "north carolina" do
      setup do
        @nc     = Factory(:state, :name => "North Carolina", :code => "NC", :country => @us)
        @object = Locality.resolve("north carolina")
      end

      should "resolve to north carolina state object" do
        assert_equal @nc, @object
      end
    end

    context "south carolina" do
      setup do
        @sc     = Factory(:state, :name => "South Carolina", :code => "SC", :country => @us)
        @object = Locality.resolve("south carolina")
      end

      should "resolve to south carolina state object" do
        assert_equal @sc, @object
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
    
    context "charlotte" do
      setup do
        @nc         = Factory(:state, :name => "North Carolina", :code => "NC", :country => @us)
        @charlotte  = Factory(:city, :name => "Charlotte", :state => @nc)
        @object     = Locality.resolve("charlotte")
      end

      should "resolve to charlotte city object" do
        assert_equal @charlotte, @object
      end
    end
  end

  context "validate city" do
    context "mis-spelled city la grange pk" do
      setup do
        @il         = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
        @la_grange  = Factory(:city, :name => "La Grange Park", :state => @il)
        @object     = Locality.validate(@il, 'city', "La Grange Pk")
      end

      should "normalize and validate to la grange city object" do
        assert_equal @la_grange, @object
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

      should "resolve to illinois zip object" do
        assert_equal @zip, @object
      end
    end

    context "28212" do
      setup do
        @nc       = Factory(:state, :name => "North Carolina", :code => "NC", :country => @us)
        @zip      = Factory(:zip, :name => "28212", :state => @nc)
        @object   = Locality.resolve("28212")
      end

      should "resolve to north carlonia zip object" do
        assert_equal @zip, @object
      end
    end
  end
  
end
