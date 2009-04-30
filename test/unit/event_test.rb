require 'test/test_helper'
require 'test/factories'

class EventTest < ActiveSupport::TestCase
  
  should_validate_presence_of :name
  should_validate_presence_of :source_type
  should_validate_presence_of :source_id
  should_belong_to            :event_venue
  should_have_one             :location
  should_have_many            :event_categories
  should_have_many            :event_tags
  
  def setup
    @us             = Factory(:us)
    @il             = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago        = Factory(:city, :name => "Chicago", :state => @il)
    @location       = Location.create(:name => "Legion of Doom", :city => @chicago)
    assert @location.valid?
    @event_venue    = Factory(:event_venue, :name => "House of Orange", :location_id => @location.id)
    assert @event_venue.valid?
    @event_category = Factory(:event_category, :name => "Music", :tags => "music,concert")
    assert @event_category.valid?
  end
  
  context "create event" do
    setup do
      # @event = Event.create(:name => "Fall Out Boy", :event_venue_id => @event_venue.id, :source_type => EventSource::Eventful, :source_id => "1")
      @event = Event.new(:name => "Fall Out Boy", :source_type => EventSource::Eventful, :source_id => "1")
      @event_venue.events.push(@event)
      assert @event.valid?
      @event_venue.reload
      @location.reload
      @chicago.reload
    end
    
    should_change "Event.count", :by => 1
    
    should "increment event venue's event count" do
      assert_equal 1, @event_venue.events_count
    end
    
    should "increment location's event count" do
      assert_equal 1, @location.events_count
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
          @event_venue.events.delete(@event)
          @event.destroy
          @event_venue.reload
          @location.reload
          @chicago.reload
        end
        
        should_change "EventCategoryMapping.count", :by => -1

        should "remove category tags from event" do
          assert_equal [], @event.event_tags.collect(&:name)
        end

        should "decrement venue's event count" do
          assert_equal 0, @event_venue.events_count
        end

        should "decrement location's event count" do
          assert_equal 0, @location.events_count
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