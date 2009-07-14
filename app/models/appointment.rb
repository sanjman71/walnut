# define exception classes
class AppointmentNotFree < Exception; end
class AppointmentInvalid < Exception; end
class TimeslotNotEmpty < Exception; end

class Appointment < ActiveRecord::Base
  belongs_to              :company
  belongs_to              :service
  belongs_to              :provider, :polymorphic => true
  belongs_to              :customer, :class_name => 'User'
  validates_presence_of   :company_id, :service_id, :start_at, :end_at, :duration
  validates_presence_of   :provider_id, :if => :provider_required?
  validates_presence_of   :provider_type, :if => :provider_required?
  validates_presence_of   :customer_id, :if => :customer_required?
  validates_inclusion_of  :mark_as, :in => %w(free work wait)
  has_one                 :invoice, :dependent => :destroy, :as => :invoiceable
  before_save             :make_confirmation_code
  after_create            :add_customer_role
  
  # Locations
  has_many                  :locatables_locations, :as => :locatable
  has_many                  :locations, :through => :locatables_locations
  
  # appointment mark_as constants
  FREE                    = 'free'      # free appointments show up as free/available time and can be scheduled
  WORK                    = 'work'      # work appointments can be scheduled in free timeslots
  WAIT                    = 'wait'      # wait appointments are waiting to be scheduled in free timeslots
  
  MARK_AS_TYPES           = [FREE, WORK, WAIT]
  
  NONE                    = 'none'      # indicates that no appointment is scheduled at this time, and therefore can be scheduled as free time
  
  # appointment confirmation code constants
  CONFIRMATION_CODE_ZERO  = '00000'
  
  named_scope :service,       lambda { |o| { :conditions => {:service_id => o.is_a?(Integer) ? o : o.id} }}
  named_scope :provider,      lambda { |provider| if (provider)
                                                    {:conditions => {:provider_id => provider.id, :provider_type => provider.class.to_s}}
                                                  else
                                                    {}
                                                  end
                                     }
  named_scope :no_provider,   { :conditions => {:provider_id => nil, :provider_type => nil} }
  named_scope :customer,      lambda { |o| { :conditions => {:customer_id => o.is_a?(Integer) ? o : o.id} }}
  named_scope :duration_gt,   lambda { |t|  { :conditions => ["duration >= ?", t] }}

  # find appointments based on a named time range, use lambda to ensure time value is evaluated at run-time
  named_scope :future,        lambda { { :conditions => ["start_at >= ?", Time.now] } }
  named_scope :past,          lambda { { :conditions => ["end_at <= ?", Time.now] } }
  
  # find appointments overlapping a time range
  named_scope :overlap,       lambda { |start_at, end_at| { :conditions => ["(start_at < ? AND end_at > ?) OR (start_at < ? AND end_at > ?) OR 
                                                                             (start_at >= ? AND end_at <= ?)", 
                                                                             start_at, start_at, end_at, end_at, start_at, end_at] }}

  # find appointments overlapping a time of day range
  named_scope :time_overlap,  lambda { |time_range| { :conditions => ["(time_start_at < ? AND time_end_at > ?) OR 
                                                                       (time_start_at < ? AND time_end_at > ?) OR 
                                                                       (time_start_at >= ? AND time_end_at <= ?)", 
                                                                       time_range.first, time_range.first, 
                                                                       time_range.last, time_range.last, 
                                                                       time_range.first, time_range.last] }}

  # find appointments by mark_as type
  MARK_AS_TYPES.each { |s| named_scope s, :conditions => {:mark_as => s} }
  
  named_scope :free_work,   { :conditions => ["mark_as = ? OR mark_as = ?", FREE, WORK]}
  named_scope :wait_work,   { :conditions => ["mark_as = ? OR mark_as = ?", WAIT, WORK]}
  
  # find appointments by state is part of the AASM plugin
  # add special named scopes for special state queries
  named_scope :upcoming_completed, { :conditions => ["state = ? or state = ?", 'upcoming', 'completed'] }
  
  # order by start_at
  named_scope :order_start_at, {:order => 'start_at'}
  
  
  # scope appointment search by a location
  
  # general_location is used for broad searches, where a search for appointments in Chicago includes appointments assigned to anywhere
  # as well as those assigned to chicago. A search for appointments assigned to anywhere includes all appointments - no constraints.
  named_scope :general_location,
                lambda { |location|
                  if (location.nil? || location.id == 0 || location.id.blank?)
                    # If the request is for any location, there is no condition
                    {}
                  else
                    # If a location is specified, we accept appointments with this location, or with "anywhere" - i.e. null location
                    { :include => :locations, :conditions => ["locations.id = '?' OR locations.id IS NULL", location.id] }
                  end
                }
  # specific_location is used for narrow searchees, where a search for appointments in Chicago includes only those appointments assigned to
  # Chicago. A search for appointments assigned to anywhere includes only those appointments - not those assigned to Chicago, for example.
  named_scope :specific_location,
                lambda { |location|
                  # If the request is for any location, there is no condition
                  if (location.nil? || location.id == 0 || location.id.blank? )
                    { :include => :locations, :conditions => ["locations.id IS NULL"] }
                  else
                    # If a location is specified, we accept appointments with this location, or with "anywhere" - i.e. null location
                    { :include => :locations, :conditions => ["locations.id = '?'", location.id] }
                  end
                }
  
  # valid when values
  WHEN_THIS_WEEK            = 'this week'
  WHEN_PAST_WEEK            = 'past week'
  WHENS                     = ['today', 'tomorrow', WHEN_THIS_WEEK, 'next week', 'later']
  WHEN_WEEKS                = [WHEN_THIS_WEEK, 'next week', 'later']
  WHENS_EXTENDED            = ['today', 'tomorrow', WHEN_THIS_WEEK, 'next week', 'next 2 weeks', 'next 4 weeks', 'this month', 'later']
  WHENS_PAST                = ['past week', 'past 2 weeks', 'past month']
  
  # valid time of day values
  TIMES                     = ['anytime', 'morning', 'afternoon', 'evening']
  TIMES_EXTENDED            = ['anytime', 'early morning', 'morning', 'afternoon', 'evening', 'late night']
  
  TIME_ANYTIME              = 'anytime'
  
  # convert time of day to a seconds range, in utc format
  TIMES_HASH                = {'anytime'    => [0,        24*3600],     # entire day
                               'morning'    => [8*3600,   12*3600],     # 8am - 12pm
                               'afternoon'  => [12*3600,  17*3600],     # 12pm - 5pm
                               'evening'    => [17*3600,  21*3600],     # 5pm - 9pm
                               'never'      => [0,        0]
                              }

  # BEGIN acts_as_state_machine
  include AASM
  
  aasm_column           :state
  aasm_initial_state    :upcoming
  aasm_state            :upcoming
  aasm_state            :completed
  aasm_state            :canceled
  
  aasm_event :checkout do
    transitions :to => :completed, :from => [:upcoming]
  end

  aasm_event :cancel do
    transitions :to => :canceled, :from => [:upcoming]
  end
  # END acts_as_state_machine

  # TODO - this overrides and fixes a bug in Rails 2.2 - ticket http://rails.lighthouseapp.com/projects/8994/tickets/1339
  def self.create_time_zone_conversion_attribute?(name, column)
    # Appointment.write_inheritable_attribute(:skip_time_zone_conversion_for_attributes, [])
    time_zone_aware_attributes && skip_time_zone_conversion_for_attributes && !skip_time_zone_conversion_for_attributes.include?(name.to_sym) && [:datetime, :timestamp].include?(column.type)
  end
  
  # map time of day string to a numeric time range, and then adjust for the time zone
  # note: no adjustment needed for anytime or never
  def self.time_range(s)
    if ['never', 'anytime'].include?(s)
      array = (TIMES_HASH[s] || TIMES_HASH['never'])
    else
      array = (TIMES_HASH[s] || TIMES_HASH['never']).map { |x| x - Time.zone.utc_offset }
    end
    Range.new(array[0], array[1])
  end
  
  def after_initialize
    # after_initialize can also be called when retrieving objects from the database
    return unless new_record?

    # initialize mark_as if its blank and we have a service
    if self.mark_as.blank? and self.service
      self.mark_as = self.service.mark_as
    end

    # for free and work appointments, force end_at to be start_at + duration (converted to seconds)
    if [FREE, WORK].include?(self.mark_as) and self.start_at and self.duration
      self.end_at = self.start_at + self.duration*60
    end

    # initialize duration (in minutes)
    if (self.service.nil? || self.service.free?) and self.duration.blank?
      # initialize duration based on start and end times
      self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
    elsif self.service and self.duration.blank?
      # initialize duration based on service duration
      self.duration = self.service.duration
    end
        
    # initialize when, time attributes with default values

    if self.when.nil?
      self.when = ''
    end

    if self.time.nil?
      self.time = ''
    end
    
    # initialize time of day attributes
    
    if self.mark_as == WAIT
      # set time to anytime for wait appointments
      self.time           = TIME_ANYTIME
      
      # set time of day values based on time value
      time_range          = Appointment.time_range(self.time)
      self.time_start_at  = time_range.first
      self.time_end_at    = time_range.last
    else
      # set time of day values based on appointment start, end times in utc format
      if self.start_at
        self.time_start_at = self.start_at.utc.hour * 3600 + self.start_at.utc.min * 60
      end

      if self.end_at
        self.time_end_at = self.end_at.utc.hour * 3600 + self.end_at.utc.min * 60
      end
    end
  end
  
  def validate
    if self.when == :error
      errors.add_to_base("When is invalid")
    end

    if self.time == :error
      errors.add_to_base("Time is invalid")
    end
    
    if self.start_at and self.end_at
      # start_at must be before end_at
      if !(start_at.to_i < end_at.to_i)
        errors.add_to_base("Appointment start time must be earlier than the apointment end time")
      end
    end
    
    if self.provider and self.company
      # provider must belong to this same company
      if !self.company.has_provider?(self.provider)
        errors.add_to_base("Provider is not associated to this company")
      end
    end
    
    if self.service
      # service must be provided by this company
      if !self.service.companies.include?(self.company)
        errors.add_to_base("Service is not offered by this company")
      end
    end
  end
  
  # START: override attribute methods
  def when=(s)
    if s.blank?
      # when can be empty
      write_attribute(:when, '')
    else
      daterange = DateRange.parse_when(s)
      
      if !daterange.valid?
        # invalid when
        write_attribute(:when , :error)
      else
        write_attribute(:when, daterange.name)
        self.start_at   = daterange.start_at
        self.end_at     = daterange.end_at
      end
    end
  end
  
  def time=(s)
    if s.blank?
      # time can be empty
      write_attribute(:time, '')
    elsif TIMES.include?(s)
      write_attribute(:time, s)
    else 
      # invalid time
      write_attribute(:time, :error)
    end
  end
  
  def time(options = {})
    @time = read_attribute(:time)
    if @time.blank? and options[:default]
      # return default value
      return options[:default]
    end
    @time
  end
  
  # END: override attribute methdos
  
  # START: virtual attributes
  def start_at_string
    self.start_at.to_s
  end
  
  def start_at_string=(s)
    # chronic parses times into the current time zone, but stored by activerecord in utc format
    self.start_at = Chronic.parse(s)
  end

  def end_at_string
    self.end_at.to_s
  end
  
  def end_at_string=(s)
    # chronic parses times into the current time zone, but stored by activerecord in utc format
    self.end_at = Chronic.parse(s)
  end
  
  def time_range=(attributes)
    case attributes.class.to_s
    when 'Hash', 'HashWithIndifferentAccess'
      time_range = TimeRange.new(attributes)
    when 'TimeRange'
      time_range = attributes
    else
      raise ArgumentError, "expected TimeRange or Hash"
    end
    self.start_at   = time_range.start_at
    self.end_at     = time_range.end_at
  end
  
  def time_range
    Range.new(time_start_at, time_end_at)
  end
  
  # appointments are only supposed to have one location
  def location
    if locations_count == 0
      # no need to query the database here
      Location.anywhere
    else
      self.locations.first
    end
  end
  
  def location=(location)
    self.locations << location
  end
  # END: virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will create a new customer if and only if the email field is unique
  def customer_attributes=(customer_attributes)
    self.customer = User.find_by_email(customer_attributes["email"]) || self.create_customer(customer_attributes)
  end
  
  # Assign a location. Don't assign if no location specified, or if Location.anywhere is specified (id == 0)
  def location_id=(id)
    self.locations << company.locations.find_by_id(id.to_i) unless (id.blank? || id.to_i == 0)
  end
  
  def cancel
    update_attribute(:canceled_at, Time.now)
    cancel!
  end
  
  # returns all appointment conflicts
  # conflict rules:
  #  - provider must be the same
  #  - start, end times must overlap
  #  - must be marked as 'free' or 'work'
  #  - state must not be 'upcoming' or 'completed'
  def conflicts
    @conflicts ||= self.company.appointments.free_work.upcoming_completed.provider(provider).overlap(start_at, end_at)
  end
  
  # returns true if this appointment conflicts with any other
  def conflicts?
    self.conflicts.size > 0
  end

  def free?
    self.mark_as == FREE
  end

  def work?
    self.mark_as == WORK
  end
  
  def wait?
    self.mark_as == WAIT
  end
  
  alias :waitlist? :wait?
  
  # return the collection of waitlist appointments that overlap with this free appointment
  def waitlist
    # check that this is a free appointment
    return [] if self.mark_as != FREE
    # find wait appointments that overlap in both date and time ranges
    @waitlist ||= self.company.appointments.wait.overlap(start_at, end_at).time_overlap(self.time_range)
  end
    
  # narrow an appointment by start, end times
  def narrow_by_time_range!(start_at, end_at)
    # validate start, end times
    raise AppointmentInvalid, "invalid narrow time range" if start_at > self.end_at or end_at < self.start_at or start_at > end_at
    
    # narrow appointment by start, end time
    self.start_at       = start_at if self.start_at < start_at
    self.end_at         = end_at if self.end_at > end_at
    self.duration       = (self.end_at.to_i - self.start_at.to_i) / 60
    
    # adjust time start, end values
    self.time_start_at  = self.start_at.utc.hour * 3600 + self.start_at.min * 60
    self.time_end_at    = self.end_at.utc.hour * 3600 + self.end_at.min * 60
  end
  
  # narrow an appointment by time of day
  def narrow_by_time_of_day!(time)
    return if time == 'anytime'
    
    request_time_range = Appointment.time_range(time)
    current_time_range = Range.new(self.time_start_at, self.time_end_at)
    
    if current_time_range.overlap?(request_time_range)
      # narrow
      if current_time_range.include?(request_time_range)
        # find and adjust by the difference in seconds
        self.start_at += (request_time_range.first - current_time_range.first).seconds
        self.end_at   += (request_time_range.last - current_time_range.last).seconds
      elsif current_time_range.include?(request_time_range.first)
        # first part of request time range overlaps
        self.start_at += (request_time_range.first - current_time_range.first)
      else
        # last part of request time range overlaps
        self.end_at   += (request_time_range.last - current_time_range.last).seconds
      end
      # adjust duration
      self.duration = (self.end_at.to_i - self.start_at.to_i) / 60
      # check special case of 0 duration
      self.start_at = nil if duration == 0
      self.end_at   = nil if duration == 0
    else
      # the requested range does not overlap - narrow to an empty appointment
      self.start_at       = nil
      self.end_at         = nil
      self.time_start_at  = nil
      self.time_end_at    = nil
      self.duration       = 0
    end
  end

  protected
  
  # providers are required for all appointments except waitlist appointments
  def provider_required?
    return false if wait?
    true
  end
  
  # customers are required for work and waitlist appointments
  def customer_required?
    return true if work? or wait?
    false
  end

  def make_confirmation_code
    unless self.confirmation_code
      if [WORK, WAIT].include?(self.mark_as)
        # create a random string
        possible_values         = ('A'..'Z').to_a + (0..9).to_a
        code_length             = 5
        self.confirmation_code  = (0...code_length).map{ possible_values[rand(possible_values.size)]}.join
      else
        # use a constant string
        self.confirmation_code  = CONFIRMATION_CODE_ZERO
      end
    end
  end
  
  # add the 'customer' role to a work/wait appointment's customer
  def add_customer_role
    return if ![WORK, WAIT].include?(self.mark_as) or self.customer.blank?
    self.customer.grant_role('customer', self.company)
  end
  
end
