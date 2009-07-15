# define exception classes
class AppointmentNotFree < Exception; end
class AppointmentInvalid < Exception; end
class TimeslotNotEmpty < Exception; end

class Recurrence < ActiveRecord::Base
  belongs_to              :company
  belongs_to              :service
  belongs_to              :provider, :polymorphic => true
  belongs_to              :customer, :class_name => 'User'
  belongs_to              :location
  has_one                 :invoice, :dependent => :destroy, :as => :invoiceable

  validates_presence_of   :company_id, :service_id, :start_at, :end_at, :duration
  validates_presence_of   :provider_id, :if => :provider_required?
  validates_presence_of   :provider_type, :if => :provider_required?
  validates_presence_of   :customer_id, :if => :customer_required?
  validates_inclusion_of  :mark_as, :in => %w(free work wait)

  before_save             :make_confirmation_code
  after_create            :add_customer_role

  # appointment mark_as constants
  FREE                    = 'free'      # free appointments show up as free/available time and can be scheduled
  WORK                    = 'work'      # work appointments can be scheduled in free timeslots
  WAIT                    = 'wait'      # wait appointments are waiting to be scheduled in free timeslots
  
  MARK_AS_TYPES           = [FREE, WORK, WAIT]
  
  NONE                    = 'none'      # indicates that no appointment is scheduled at this time, and therefore can be scheduled as free time
  
  # appointment confirmation code constants
  CONFIRMATION_CODE_ZERO  = '00000'
  
  named_scope :service,       lambda { |o| { :conditions => {:service_id => o.is_a?(Integer) ? o : o.id} }}
  named_scope :provider,      lambda { |provider| 
                                        if (provider)
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
  named_scope :overlap,       lambda { |start_at, end_at|
                                        { :conditions => ["(start_at < ? AND end_at > ?) OR (start_at < ? AND end_at > ?)
                                                            OR (start_at >= ? AND end_at <= ?)",
                                            start_at, start_at, end_at, end_at, start_at, end_at]
                                        }
                                      }

  # find appointments overlapping a time of day range
  named_scope :time_overlap,  lambda { |time_range|
                                        { :conditions => ["(time_start_at < ? AND time_end_at > ?) OR 
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
                    { :conditions => ["location_id = '?' OR location_id IS NULL", location.id] }
                  end
                }
  # specific_location is used for narrow searchees, where a search for appointments in Chicago includes only those appointments assigned to
  # Chicago. A search for appointments assigned to anywhere includes only those appointments - not those assigned to Chicago, for example.
  named_scope :specific_location,
                lambda { |location|
                  # If the request is for any location, there is no condition
                  if (location.nil? || location.id == 0 || location.id.blank? )
                    { :conditions => ["location_id IS NULL"] }
                  else
                    # If a location is specified, we accept appointments with this location, or with "anywhere" - i.e. null location
                    { :conditions => ["location_id = '?'", location.id] }
                  end
                }


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

    # initialize time of day attributes
    # set time of day values based on appointment start, end times in utc format
    if self.start_at
      self.time_start_at = self.start_at.utc.hour * 3600 + self.start_at.utc.min * 60
    end

    if self.end_at
      self.time_end_at = self.end_at.utc.hour * 3600 + self.end_at.utc.min * 60
    end
  end
  
  def validate

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

  # END: virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will create a new customer if and only if the email field is unique
  def customer_attributes=(customer_attributes)
    self.customer = User.find_by_email(customer_attributes["email"]) || self.create_customer(customer_attributes)
  end
  
  # Assign a location. Don't assign if no location specified, or if Location.anywhere is specified (id == 0)
  def location_id=(id)
    self.location_id = company.locations.find_by_id(id.to_i) unless (id.blank? || id.to_i == 0)
  end
  
  def cancel
    update_attribute(:canceled_at, Time.now)
    cancel!
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
  
  # iCalendar uid attribute
  def uid
    "#{self.created_at}-r-#{self.id}@walnutindustries.com"
  end
  
  def create_instances(company, start_at, end_at)
    # Create a RiCal calendar with our recurring appointments
    company.recurrences.each do |recur|
      cal = RiCal.Calendar do |cal|
        cal.event do |ev|
          ev.add_attendee "#{recur.provider.email}"
          # No customer if this is available time
          if recur.service.mark_as == "free"
            ev.summary = "#{recur.provider.name}: Available"
          else
            ev.summary = "#{recur.provider.name}: #{recur.service.name} for #{recur.customer.name}"
            ev.add_attendee "#{recur.customer.email}"
          end
          ev.dtstart = recur.start_at
          ev.dtend =recur.end_at
          if recur.location
            ev.location = "#{recur.location.name}"
          end
          if recur.notes.size > 0
            ev.description = "Notes: \n #{recur.notes.map(&:comment).join}"
          end
          ev.rrule = recur.rrule
        end
      end
      cal.occurrences(:starting => start_at, :before => end_at).each do |appt|
        # Create an appointment 
        Appointment.create(:company => recur.company, :service => recur.service, :provider => recur.provider, :customer => recur.customer, :start_at => appt.start, :end_at => appt.end, :mark_as => recur.mark_as, :state => 'upcoming', :uid => recur.uid)
      end
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
