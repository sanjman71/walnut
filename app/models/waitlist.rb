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

  after_create                :grant_company_customer_role, :create_appointment_waitlist

  has_many                      :waitlist_time_ranges, :dependent => :destroy
  accepts_nested_attributes_for :waitlist_time_ranges, :allow_destroy => true

  has_many                    :appointment_waitlists, :dependent => :destroy

  named_scope :service,       lambda { |o| { :conditions => {:service_id => o.is_a?(Integer) ? o : o.id} }}
  named_scope :provider,      lambda { |provider| if (provider)
                                                    {:conditions => {:provider_id => provider.id, :provider_type => provider.class.to_s}}
                                                  else
                                                    {}
                                                  end
                                      }

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

  protected

  # add 'company customer' role to the waitlist customer
  def grant_company_customer_role
    self.customer.grant_role('company customer', self.company) unless self.customer.has_role?('company customer', self.company)
  end

  def create_appointment_waitlist
    AppointmentWaitlist.create_waitlist(self)
  end
end