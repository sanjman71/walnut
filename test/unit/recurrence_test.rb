require 'test/test_helper'

# 
# Note: A recurrence test also exists in peanut.  The tests here test recurrences with respect to events, 
# which are used heavily in walnut.
#

class RecurrenceTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :company_id
  should_validate_presence_of   :start_at
  should_validate_presence_of   :end_at
  should_validate_presence_of   :duration
  should_allow_values_for       :mark_as, "free", "work", "wait"

  should_belong_to              :company
  should_belong_to              :service
  should_belong_to              :provider
  should_belong_to              :customer
  should_belong_to              :location
  should_have_one               :invoice
  should_have_many              :appointments

  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)

    @location = Factory(:location, :country => @us, :state => @il, :city => @chicago, :zip => @zip)
    @company  = Factory(:company, :name => "Chicago Pizza")
    @company.locations.push(@location)
  end
  
  context "recurrence" do
    setup do
      @start_at_utc = Time.now.utc.beginning_of_day
      @end_at_utc   = @start_at_utc + 2.hours
      @rrule        = "FREQ=DAILY";
      @recurrence   = Recurrence.create(:company => @company, :location_id => @location.id, :name => "Happy Hour",
                                        :start_at => @start_at_utc, :end_at => @end_at_utc,
                                        :rrule => @rrule, :mark_as => Appointment::FREE, :public => true)
    end
    
    should_change "Recurrence.count", :by => 1
    
    context "expand 1 instance" do
      setup do
        @appointments = @recurrence.expand_instances(Time.now, Time.now + 3.months, 1)
      end
      
      should_change "Appointment.count", :by => 1
      
      should "return 1 appointment" do
        assert_equal 1, @appointments.size
      end
      
      should "copy recurrence name to appointment" do
        @appointment = @appointments.first
        assert_equal "Happy Hour", @appointment.name
      end

      should "copy recurrence start, end hours and duration to appointment" do
        @appointment = @appointments.first
        assert_equal 0, @appointment.start_at.utc.hour
        assert_equal 2, @appointment.end_at.utc.hour
        assert_equal 120, @appointment.duration
      end
      
      should "should increment location.appointments_count" do
        assert_equal 1, @location.reload.appointments_count 
      end
      
      should "should increment location.events_count" do
        assert_equal 1, @location.reload.events_count 
      end
    end
  end
end