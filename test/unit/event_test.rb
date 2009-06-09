require 'test/test_helper'
require 'test/factories'

class EventTest < ActiveSupport::TestCase
  
  should_validate_presence_of :name
  should_belong_to            :location
  should_have_many            :event_categories
  should_have_many            :event_tags
  
  def setup
    @us             = Factory(:us)
    @il             = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago        = Factory(:city, :name => "Chicago", :state => @il)
    @location       = Location.create(:city => @chicago, :source_id => 100, :source_type => "Somebody")
    assert @location.valid?
    @place          = Place.create(:name => "Kickass Ampthitheater")
    assert @place.valid?
    @place.locations.push(@location)
    @location.reload
    assert_equal @place, @location.place
    @event_venue    = Factory(:event_venue, :name => "House of Pain", :location_id => @location.id)
    assert @event_venue.valid?
    @event_venue.reload
    @event_category = Factory(:event_category, :name => "Music", :tags => "music,concert")
    assert @event_category.valid?
  end
  
  context "validate event venue source is 'Digest'" do
    should "have location_source_type with 'Digest'" do
      assert_match /Digest/, @event_venue.location_source_type
    end

    should "have location_source_id with digest value" do
      assert_equal "3fca59290310e24f5447bb23f6022248", @event_venue.location_source_id
    end
  end
  
  context "create event venue mapped to a location from a localeze base record" do
    setup do
      @hall_of_justice = Location.create(:city => @chicago, :source_id => 101, :source_type => "Localeze::BaseRecord")
      assert @hall_of_justice.valid?
      @hall_venue = Factory(:event_venue, :name => "Hall of Justice Venue", :location_id => @hall_of_justice.id)
      assert @hall_venue.valid?
    end

    should "have location_source_type with localeze value" do
      assert_match /Localeze::BaseRecord/, @hall_venue.location_source_type
    end
    
    should "have location_source_id == 101" do
      assert_equal '101', @hall_venue.location_source_id
    end
  end
  
  context "create event" do
    setup do
      @event = Event.new(:name => "Fall Out Boy", :source_type => EventSource::Eventful, :source_id => "1")
      assert @event.valid?
      @location.events.push(@event)
      @location.reload
      @place.reload
      @chicago.reload
    end
    
    should_change "Event.count", :by => 1
    
    should "add event to location events collection" do
      assert_equal [@event], @location.events
    end

    should "increment location's event count" do
      assert_equal 1, @location.events_count
    end
    
    should "have venue name Kickass Ampthitheater" do
      assert_equal "Kickass Ampthitheater", @event.venue_name
    end
    
    should "add event to event venue events collection" do
      assert_equal [@event], @event_venue.events
    end
    
    should "increment event venue's event count" do
      assert_equal 1, @event_venue.events_count
    end

    should "increment location's popularity value" do
      assert_equal 1, @location.popularity
    end
    
    should "add tag 'venue' to location place" do
      assert_equal ["venue"], @place.tag_list
    end
    
    context "then add event category with tags" do
      setup do
        @event.event_categories.push(@event_category)
        @event_category.reload
      end
      
      should_change "EventCategoryMapping.count", :by => 1
      
      should "apply category tags to event" do
        assert_equal ["music", "concert"], @event.event_tags.collect(&:name)
      end
      
      should "increment event_category.events_count" do
        assert_equal 1, @event_category.events_count
      end
      
      context "then remove event category" do
        setup do
          @event.event_categories.delete(@event_category)
          @event_category.reload
        end

        should_change "EventCategoryMapping.count", :by => -1

        should "remove category tags from event" do
          assert_equal [], @event.event_tags.collect(&:name)
        end

        should "decrement event_category.events_count" do
          assert_equal 0, @event_category.events_count
        end
      end
      
      context "then remove event that has an event category" do
        setup do
          @event.destroy
          @event_venue.reload
          @location.reload
          @place.reload
          @chicago.reload
        end
        
        should_change "EventCategoryMapping.count", :by => -1

        should "remove category tags from event" do
          assert_equal [], @event.event_tags.collect(&:name)
        end

        should "remove event from location event collection" do
          assert_equal [], @location.events
        end
        
        should "decrement location event count" do
          assert_equal 0, @location.events_count
        end

        should "decrement location's popularity value" do
          assert_equal 0, @location.popularity
        end

        should "remove event from venue event collection" do
          assert_equal [], @event_venue.events
        end

        should "decrement venue event count" do
          assert_equal 0, @event_venue.events_count
        end

        should "remove tag 'venue' from location place" do
          assert_equal [], @place.tag_list
        end
      end
    end

    context "then add event category with no tags" do
      setup do
        @event_category2 = Factory(:event_category, :name => "Nothing")
        assert @event_category2.valid?
        @event.event_categories.push(@event_category2)
        @event_category2.reload
      end

      should_change "EventCategoryMapping.count", :by => 1
      
      should "have no event tags" do
        assert_equal [], @event.event_tags
      end
    end
  end
end