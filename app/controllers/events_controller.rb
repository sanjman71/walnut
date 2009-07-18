class EventsController < ApplicationController
  before_filter :init_location
  
  privilege_required 'manage site', :on => :current_user

  def new
    # @location, @company initialized in before filter

    @repeat_options = ["Does Not Repeat", "Every Weekday (Monday - Friday)", "Daily", "Weekly"]
  end

  def create
    # @location, @company initialized in before filter

    @name         = params[:name].to_s

    @dstart       = params[:dstart].to_s
    @tstart       = params[:tstart].to_s
    @tend         = params[:tend].to_s

    # build dtstart and dtend
    @dtstart      = "#{@dstart}T#{@tstart}"
    @dtend        = "#{@dstart}T#{@tend}"

    # build start_at and end_at times
    @start_at_utc = Time.parse(@dtstart).utc
    @end_at_utc   = Time.parse(@dtend).utc

    # get recurrence parameters
    @freq         = params[:freq].to_s.upcase
    @byday        = params[:byday].to_s.upcase
    @until        = params[:until].to_s
    @interval     = params[:interval].to_i

    if !@freq.blank?
      # build recurrence rule from rule components
      tokens = ["FREQ=#{@freq}"]

      unless @byday.blank?
        tokens.push("BYDAY=#{@byday}")
      end

      unless @until.blank?
        tokens.push("UNTIL=#{@until}T000000Z")
      end

      @rrule = tokens.join(";")
    end
    
    if @rrule.blank?
      # create event, which are always public and marked as 'free'
      @appointment = @location.appointments.create(:company => @company, :name => @name, :start_at => @start_at_utc, :end_at => @end_at_utc, 
                                                   :mark_as => Appointment::FREE, :public => true)


      if @appointment.valid?
        flash[:notice] = "Created event #{@name}"
      else
        @error = true
        flash[:error] = "Could not create event #{@name}"
      end
    else
      # create event recurrence, which are always public and marked as 'free'
      @recurrence = Recurrence.create(:company => @company, :location_id => @location.id, :name => @name, :start_at => @start_at_utc, :end_at => @end_at_utc,
                                      :rrule => @rrule, :mark_as => Appointment::FREE, :public => true)

      if @recurrence.valid?
        # expand the occurrence exactly once within a reasonable time frame to create at most one appointment
        recur_start   = Time.now
        recur_before  = Time.now + 3.months
        @recurrence.expand_instances(recur_start, recur_before, 1)
        flash[:notice] = "Created event #{@name}"
      else
        @error = true
        flash[:error] = "Could not create event #{@name}"
      end
    end

    respond_to do |format|
      format.html do
        if @error
          render(:action => 'new')
        else
          redirect_to(location_path(@location))
        end
      end
    end

  end
  
  def show
    # @location, @company initialized in before filter
    
  end
  
  protected
  
  def init_location
    @location = Location.find(params[:location_id].to_i)
    @company  = @location.company
  end
  
end