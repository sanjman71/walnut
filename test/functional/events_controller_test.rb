require 'test/test_helper'

class EventsControllerTest < ActionController::TestCase
  
  should_route :get,  '/locations/1/events/new', :controller => 'events', :action => 'new', :location_id => '1'
  should_route :post, '/locations/1/events', :controller => 'events', :action => 'create', :location_id => '1'
    
  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @z60610   = Factory(:zip, :name => "60610", :state => @il)

    @location = Factory(:location, :country => @us, :state => @il, :city => @chicago, :zip => @zip)
    @company  = Factory(:company, :name => "Chicago Pizza")
    @company.locations.push(@location)
    
    @controller = EventsController.new
  end

  context "create one-time event" do
    setup do
      @updated_at = @location.updated_at
      # stub user privileges
      @controller.stubs(:current_privileges).returns(["manage site"])
      post :create,
           {:name => 'Wings Special', :location_id => @location.id, :dstart => "20090201", :tstart => "090000", :tend => "110000", :freq => ''}
    end

    should_change "Appointment.count", :by => 1
    should_not_change "Recurrence.count"
    
    should "mark appointment as public" do
      assert_equal true, assigns(:appointment).public
    end
        
    should "increment location.events_count" do
      assert_equal 1, @location.reload.events_count
    end

    should "increment location.appointments_count" do
      assert_equal 1, @location.reload.appointments_count
    end
    
    should "update location.updated_at timestamp" do
      assert_not_equal @updated_at, @location.reload.updated_at
    end
    
    should_respond_with :redirect
    should_redirect_to("location show") { location_path(@location) }
  end
  
  # context "create recurrence event" do
  #   context "weekly" do
  #     setup do
  #       @controller.stubs(:current_privileges).returns(["manage site"])
  #       post :create,
  #            {:name => 'Wings Special', :location_id => @location.id, :dstart => "20090201", :tstart => "090000", :tend => "110000", 
  #             :freq => 'weekly', :byday => 'mo'}
  #     end
  #   
  #     # should_assign_to(:dtstart) { "20090201T090000" }
  #     # should_assign_to(:dtend) { "20090201T110000" }
  #     # should_assign_to(:rrule) { "FREQ=WEEKLY;BYDAY=MO" }
  #   
  #     should_change "Recurrence.count", :by => 1
  #     # should_change "Appointment.count", :by => 4  # 4 weeks, 1 appt a week
  #   end
  # end
end