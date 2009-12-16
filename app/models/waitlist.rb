class Waitlist < ActiveRecord::Base
  belongs_to                  :company
  belongs_to                  :service
  belongs_to                  :provider, :polymorphic => true
  belongs_to                  :customer, :class_name => 'User'
  belongs_to                  :creator, :class_name => 'User'
  belongs_to                  :location

  validates_presence_of       :company_id
  validates_presence_of       :service_id
  validates_presence_of       :customer_id
  # validates_presence_of       :provider_id, :if => :provider_required?
  # validates_presence_of       :provider_type, :if => :provider_required?

  after_create                :grant_company_customer_role

  has_many                      :waitlist_time_ranges, :dependent => :destroy, :after_add => :after_add_waitlist_time_range
  accepts_nested_attributes_for :waitlist_time_ranges, :allow_destroy => true

  has_many                    :appointment_waitlists, :dependent => :destroy

  named_scope :company,       lambda { |o| { :conditions => {:company_id => o.is_a?(Integer) ? o : o.id} }}
  named_scope :service,       lambda { |o| { :conditions => {:service_id => o.is_a?(Integer) ? o : o.id} }}
  named_scope :provider,      lambda { |provider| if (provider)
                                                    {:conditions => {:provider_id => provider.id, :provider_type => provider.class.to_s}}
                                                  else
                                                    {}
                                                  end
                                      }
                                      
  # find waitlists with at least 1 past waitlist time range
  named_scope :past,          lambda { { :include => :waitlist_time_ranges, :conditions => ["waitlist_time_ranges.end_date < ?", Time.zone.now] } }

  # find appointments overlapping a time range
  named_scope :date_overlap,  lambda { |start_date, end_date| { :joins => :waitlist_time_ranges,
                                                                :conditions => ["(waitlist_time_ranges.start_date < ? AND waitlist_time_ranges.end_date > ?) OR 
                                                                                 (waitlist_time_ranges.start_date < ? AND waitlist_time_ranges.end_date > ?) OR 
                                                                                 (waitlist_time_ranges.start_date >= ? AND waitlist_time_ranges.end_date <= ?)", 
                                                                                 start_date, start_date, end_date, end_date, start_date, end_date] }}

  # find appointments overlapping a time of day range
  named_scope :time_overlap,  lambda { |start_time, end_time| { :joins => :waitlist_time_ranges, 
                                                                :conditions => ["(waitlist_time_ranges.start_time < ? AND waitlist_time_ranges.end_time > ?) OR 
                                                                                 (waitlist_time_ranges.start_time < ? AND waitlist_time_ranges.end_time > ?) OR 
                                                                                 (waitlist_time_ranges.start_time >= ? AND waitlist_time_ranges.end_time <= ?)", 
                                                                                 start_time, start_time, end_time, end_time, start_time, end_time] }}


  # order by start_at
  named_scope :order_start_at,  {:order => 'waitlist_time_ranges.start_time'}

  # find matching waitlists for the specified range
  def self.find_matching(company, location, provider, daterange)
    # company.waitlists.provider(provider).date_overlap(daterange.start_at, daterange.end_at).general_location(location).order_start_at
    company.waitlists.provider(provider).date_overlap(daterange.start_at, daterange.end_at).all(:include => :waitlist_time_ranges)
  end

  # find all available free time
  def available_free_time
    duration      = service.duration
    appointments  =  waitlist_time_ranges.inject([]) do |array, waitlist_time_range|
      # find free appointments for a specific provider, order by start times
      start_date    = waitlist_time_range.start_date
      end_date      = waitlist_time_range.end_date
      time_range    = [waitlist_time_range.start_time, waitlist_time_range.end_time]
      array         += company.appointments.free.provider(provider).overlap(start_date, end_date).time_overlap(time_range).duration_gt(duration).order_start_at
    end
    appointments
  end

  # expand over all days in the waitlist
  def expand_days(options={})
    @start_day = options[:start_day].to_s(:appt_schedule_day) unless options[:start_day].blank?
    @end_day   = options[:end_day].to_s(:appt_schedule_day) unless options[:end_day].blank?
    @days      = []

    waitlist_time_ranges.each do |time_range|
      # expand time range start date to end date
      @time_range_start_day = time_range.start_date.to_s(:appt_schedule_day)
      @time_range_end_day   = time_range.end_date.to_s(:appt_schedule_day)

      # adjust date range based on constraints
      if @start_day and @time_range_start_day < @start_day
        @time_range_start_day = @start_day
      end

      if @end_day and @time_range_end_day > @end_day
        @time_range_end_day = @end_day
      end

      Range.new(Date.parse(@time_range_start_day), Date.parse(@time_range_end_day)).collect do |date|
        # return date as a datetime object in the local time zone
        @days.push([self, date.to_time.in_time_zone.beginning_of_day, time_range])
      end
    end
    @days
  end

  protected

  # add 'company customer' role to the waitlist customer
  def grant_company_customer_role
    self.customer.grant_role('company customer', self.company) unless self.customer.has_role?('company customer', self.company)
  end

  def after_add_waitlist_time_range(waitlist_time_range)
    # the callback can be invoked on new records, make sure we skip these
    return if self.new_record?
    if RAILS_ENV == 'development'
      AppointmentWaitlist.create_waitlist(self)
    end
  end
end