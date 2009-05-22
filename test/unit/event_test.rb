require 'test/test_helper'
require 'test/factories'

class EventTest < ActiveSupport::TestCase
  
  should_validate_presence_of :name
  should_belong_to            :event_venue
  should_belong_to            :location
  should_have_many            :event_categories
  should_have_many            :event_tags
  
  def setup
    @us             = Factory(:us)
    @il             = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago        = Factory(:city, :name => "Chicago", :state => @il)
    @location       = Location.create(:name => "Legion of Doom", :city => @chicago, :source_id => 100, :source_type => "Somebody")
    assert @location.valid?
    @event_venue    = Factory(:event_venue, :name => "House of Pain", :location_id => @location.id)
    assert @event_venue.valid?
    @event_category = Factory(:event_category, :name => "Music", :tags => "music,concert")
    assert @event_category.valid?
  end
  
  context "validate event venue" do
    should "have location_source_id == 0" do
      assert_equal 0, @event_venue.location_source_id
    end

    should "have location_source_type with digest value" do
      assert_match /Digest:\w+/, @event_venue.location_source_type
    end
  end
  
  context "create event" do
    setup do
      @event = Event.new(:name => "Fall Out Boy", :source_type => EventSource::Eventful, :source_id => "1")
      assert @event.valid?
      @event_venue.events.push(@event)
      @event_venue.reload
      @location.events.push(@event)
      @location.reload
      @chicago.reload
    end
    
    should_change "Event.count", :by => 1
    
    should "add event to location events collection" do
      assert_equal [@event], @location.events
    end

    should "increment location's event count" do
      assert_equal 1, @location.events_count
    end
    
    should "add event to event venue events collection" do
      assert_equal [@event], @event_venue.events
    end
    
    should "increment event venue's event count" do
      assert_equal 1, @event_venue.events_count
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

        should "remove event from venue event collection" do
          assert_equal [], @event_venue.events
        end

        should "decrement venue event count" do
          assert_equal 0, @event_venue.events_count
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