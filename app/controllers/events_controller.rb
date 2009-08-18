class EventsController < ApplicationController
  before_filter :init_location, :only => [:new, :create]
  
  privilege_required 'manage site', :on => :current_user, :unless => :auth_token?

  def index
    # show event cities, assume they are the densest cities
    @event_cities = City.min_density(City.popular_density).order_by_density(:include => :state).sort_by { |o| o.name }
    # @event_cities = City.with_events.order_by_density(:include => :state).sort_by { |o| o.name }
  end

  def import
    @city = City.find_by_name(params[:city].titleize, :include => :state) unless params[:city].blank?

    if params[:city].blank?
      # queue jobs
      Delayed::Job.enqueue(EventJob.new(:method => 'import_all', :limit => 100), EventJob.import_priority)
      Delayed::Job.enqueue(SphinxJob.new(:index => 'appointments'), -1)
      Delayed::Job.enqueue(EventJob.new(:method => 'set_event_counts'), -1)
      flash[:notice] = "Importing all city events"
    elsif @city.blank?
      flash[:error]  = "Could not find city #{params[:city]}"
    else
      # queue jobs
      Delayed::Job.enqueue(EventJob.new(:method => 'import_city', :city => @city.name, :region => @city.state.name, :limit => 10), EventJob.import_priority)
      Delayed::Job.enqueue(SphinxJob.new(:index => 'appointments'), -1)
      Delayed::Job.enqueue(EventJob.new(:method => 'set_event_counts'), -1)
      flash[:notice] = "Importing #{@city.name} events"
    end

    redirect_to events_path and return
  end

  def remove
    # queue job
    Delayed::Job.enqueue(EventJob.new(:method => 'remove_past'), 3)
    Delayed::Job.enqueue(SphinxJob.new(:index => 'appointments'), -1)
    Delayed::Job.enqueue(EventJob.new(:method => 'set_event_counts'), -1)
    flash[:notice] = "Removing past events"

    redirect_to events_path and return
  end

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

      @recur_rule = tokens.join(";")
    end
  
    # build appointment options hash; events are always public and marked as 'free'
    options = Hash[:company => @company, :name => @name, :creator => current_user, :start_at => @start_at_utc, :end_at => @end_at_utc, 
                   :mark_as => Appointment::FREE, :public => true]
    # add optional recurrence if specified
    options[:recur_rule] = @recur_rule if !@recur_rule.blank?

    # create event, possibly recurring
    @appointment = @location.appointments.create(options)

    if @appointment.valid?
      flash[:notice] = "Created event #{@name}"
    else
      @error = true
      flash[:error] = "Could not create event #{@name}"
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