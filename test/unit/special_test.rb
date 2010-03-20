require 'test/test_helper'

class SpecialTest < ActiveSupport::TestCase

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)
    @tag      = Tag.create(:name => 'food')
    @company  = Company.create(:name => "My Company", :time_zone => "UTC")
    @location = Location.create(:name => "Home", :country => @us, :state => @il, :city => @chicago, :street_address => '100 W Grand Ave',
                                :lat => 41.891737, :lng => -87.631483)
    @company.locations.push(@location)
  end

  context "preferences" do
    setup do
      @prefs = Special.preferences(Hash[:special_drink => '$1 car bombs', :special_food => '$1 cheeseburgers', :special_wine => "1/2 price bottles"])
    end

    should "return prefs with 3 items" do
      assert_equal 3, @prefs.size
    end
    
    should "return prefs special_drink" do
      assert_equal '$1 car bombs', @prefs[:special_drink]
    end

    should "return prefs special_food" do
      assert_equal '$1 cheeseburgers', @prefs[:special_food]
    end

    should "return prefs special_wine" do
      assert_equal '1/2 price bottles', @prefs[:special_wine]
    end
  end

  context "create" do
    setup do
      @start_at   = DateRange.find_next_date("monday")
      @end_at     = @start_at.end_of_day
      @recur_rule = "FREQ=WEEKLY;BYDAY=MO";
      @special    = Special.create('', @location, @recur_rule, :start_at => @start_at, :end_at => @end_at)
    end

    should_change("appointment count", :by => 1) { Appointment.count }
    should_change("tagging count", :by => 2) { Tagging.count }

    should "add tags 'monday', 'special'" do
      assert_equal ['monday', 'special'], @special.reload.tag_list.sort
    end

    context "then remove" do
      setup do
        @special.destroy
      end

      should_change("appointment count", :by => -1) { Appointment.count }
      should_change("tagging count", :by => -2) { Tagging.count }
    end

    context "with tags" do
      setup do
        @start_at   = DateRange.find_next_date("monday")
        @end_at     = @start_at.end_of_day
        @recur_rule = "FREQ=WEEKLY;BYDAY=MO";
        @tags       = ['food', 'drink']
        @special    = Special.create("", @location, @recur_rule, :start_at => @start_at, :end_at => @end_at, :tags => @tags)
      end

      should_change("appointments count", :by => 1) { Appointment.count }

      should "add tags" do
        assert_equal ['drink', 'food', 'monday', 'special'], @special.reload.tag_list.sort
      end
    end

    context "with preferences" do
      setup do
        @start_at     = DateRange.find_next_date("monday")
        @end_at       = @start_at.end_of_day
        @recur_rule   = "FREQ=WEEKLY;BYDAY=MO";
        @preferences  = Hash[:special_drink => "$4 Car Bombs", :special_food => "$1 Burgers"]
        @special      = Special.create("Monday Happy Hour", @location, @recur_rule, :start_at => @start_at, :end_at => @end_at, :preferences => @preferences)
      end

      should_change("appointments count", :by => 1) { Appointment.count }

      should "add tags" do
        assert_equal ['monday', 'special'], @special.reload.tag_list.sort
      end

      should "add preference special_drink" do
        assert_equal "$4 Car Bombs", @special.reload.preferences[:special_drink]
      end

      should "add preference special_food" do
        assert_equal "$1 Burgers", @special.reload.preferences[:special_food]
      end
    end
  end

  context "find by day" do
    setup do
      @start_at   = DateRange.find_next_date("monday")
      @end_at     = @start_at.end_of_day
      @recur_rule = "FREQ=WEEKLY;BYDAY=MO";
      @special    = Special.create("Monday Happy Hour", @location, @recur_rule, :start_at => @start_at, :end_at => @end_at)
    end

    should "find monday specials" do
      assert_equal [@special], Special.find_by_day(@location, 'monday')
    end

    should "not find tuesday specials" do
      assert_equal [], Special.find_by_day(@location, 'tuesday')
    end
  end
  

end