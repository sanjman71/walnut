require 'test/test_helper'
require 'test/factories'

class AppointmentTest < ActiveSupport::TestCase
  
  # should_validate_presence_of :name
  should_validate_presence_of :company_id
  should_belong_to            :location
  should_have_many            :event_categories
  should_have_many            :event_tags
  
  def setup
    @us             = Factory(:us)
    @il             = Factory(:il, :country => @us)
    @chicago        = Factory(:chicago, :state => @il)
    @location       = Location.create(:city => @chicago, :state => @il, :country => @us)
    assert @location.valid?
    @company        = Factory(:company, :name => "Kickass Ampthitheater")
    assert @company.valid?
    @company.locations.push(@location)
    @location.reload
    assert_equal @company, @location.company
    @event_venue    = Factory(:event_venue, :name => "House of Pain", :location_id => @location.id, :city => @chicago.name)
    assert @event_venue.valid?
    @event_venue.reload
    @event_category = Factory(:event_category, :name => "Music", :tags => "music,concert")
    assert @event_category.valid?
  end
  
  context "validate event venue source is nil" do
    should "have location_source_type is nil" do
      assert_equal nil, @event_venue.location_source_type
    end

    should "have location_source_id is nil" do
      assert_equal nil, @event_venue.location_source_id
    end
  end
  
  context "create event venue mapped to a location sourced from localeze" do
    setup do
      @location.location_sources.push(LocationSource.new(:source_id => 101, :source_type => "Localeze::BaseRecord"))
      @new_venue = Factory(:event_venue, :name => "New Venue", :location_id => @location.id, :city => @chicago.name)
      assert @new_venue.valid?
    end

    should_change "LocationSource.count", :by => 1
    
    should "have location_source_type with localeze value" do
      assert_match /Localeze::BaseRecord/, @new_venue.location_source_type
    end
    
    should "have location_source_id == 101" do
      assert_equal '101', @new_venue.location_source_id
    end
  end
  
  context "create event" do
    setup do
      @appointment = Appointment.create(:name => "Fall Out Boy", :source_type => EventSource::Eventful, :source_id => "1",
                                      :public => true, :mark_as => Appointment::FREE, :company => @company, 
                                      :start_at => Time.now, :end_at => Time.now + 2.hours)
      assert @appointment.valid?
      @location.appointments.push(@appointment)
      @location.reload
      @company.reload
      @chicago.reload
    end
    
    should_change "Appointment.count", :by => 1
    
    should "add event to location.appointments collection" do
      assert_equal [@appointment], @location.appointments
    end

    should "increment location's event count" do
      assert_equal 1, @location.events_count
    end
    
    should "have venue name Kickass Ampthitheater" do
      assert_equal "Kickass Ampthitheater", @appointment.venue_name
    end
    
    should "add event to event venue events collection" do
      assert_equal [@appointment], @event_venue.events
    end
    
    should "increment event venue's event count" do
      assert_equal 1, @event_venue.events_count
    end

    should "increment location's popularity value" do
      assert_equal 1, @location.popularity
    end
    
    should "add tag 'venue' to location company" do
      assert_equal ["venue"], @company.tag_list
    end
    
    context "then add event category with tags" do
      setup do
        @appointment.event_categories.push(@event_category)
        @event_category.reload
        @appointment.reload
      end
      
      should_change "AppointmentEventCategory.count", :by => 1
      
      should "apply category tags to event" do
        assert_equal ["music", "concert"], @appointment.event_tags.collect(&:name)
      end
      
      should "increment event_category.events_count" do
        assert_equal 1, @event_category.events_count
      end
      
      should "increment event.taggings_count to 2" do
        assert_equal 2, @appointment.taggings_count
      end
      
      context "then remove event category" do
        setup do
          @appointment.event_categories.delete(@event_category)
          @event_category.reload
          @appointment.reload
        end

        should_change "AppointmentEventCategory.count", :by => -1

        should "remove category tags from event" do
          assert_equal [], @appointment.event_tags.collect(&:name)
        end

        should "decrement event_category.events_count" do
          assert_equal 0, @event_category.events_count
        end

        should "decrement event.taggings_count to 0" do
          assert_equal 0, @appointment.taggings_count
        end
      end
      
      context "then remove event that has an event category" do
        setup do
          @appointment.destroy
          @event_venue.reload
          @location.reload
          @company.reload
          @chicago.reload
        end
        
        should_change "AppointmentEventCategory.count", :by => -1

        should "remove category tags from event" do
          assert_equal [], @appointment.event_tags.collect(&:name)
        end

        should "remove event from location event collection" do
          assert_equal [], @location.appointments
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

        should "remove tag 'venue' from location company" do
          assert_equal [], @company.tag_list
        end
      end
    end

    context "then add event category with no tags" do
      setup do
        @event_category2 = Factory(:event_category, :name => "Nothing")
        assert @event_category2.valid?
        @appointment.event_categories.push(@event_category2)
        @event_category2.reload
      end

      should_change "AppointmentEventCategory.count", :by => 1
      
      should "have no event tags" do
        assert_equal [], @appointment.event_tags
      end
      
      should "not change event.taggings.count" do
        assert_equal 0, @appointment.taggings_count
      end
    end
  end
end