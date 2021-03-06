require 'serialized_hash'

# define exception classes
class AppointmentNotFree < Exception; end
class AppointmentInvalid < Exception; end
class TimeslotNotEmpty < Exception; end

class Appointment < ActiveRecord::Base
  belongs_to                  :company
  belongs_to                  :service
  belongs_to                  :provider, :polymorphic => true
  belongs_to                  :customer, :class_name => 'User'
  belongs_to                  :creator, :class_name => 'User'
  belongs_to                  :location
  has_many                    :message_topics, :as => :topic
  has_many                    :messages, :through => :message_topics
  has_one                     :invoice, :dependent => :destroy, :as => :invoiceable

  # Recurrences - an appointment might have a recurrence rule. If so, the appointment may have multiple recurrence instances.
  # These recurrence instances refer back to their parent. If their parent is destroyed, the instance refererences are nullified
  has_many                    :recur_instances, :class_name => "Appointment", :foreign_key => "recur_parent_id", :dependent => :destroy
  belongs_to                  :recur_parent, :class_name => "Appointment"

  has_many                    :appointment_waitlists, :dependent => :destroy
  has_many                    :waitlists, :through => :appointment_waitlists

  # appointment mark_as constants
  FREE                    = 'free'      # free appointments show up as free/available time and can be scheduled
  WORK                    = 'work'      # work appointments can be scheduled in free timeslots
  VACATION                = 'vacation'

  MARK_AS_TYPES           = [FREE, WORK, VACATION]

  NONE                    = 'none'      # indicates that no appointment is scheduled at this time, and therefore can be scheduled as free time

  # appointment confirmation code constants
  CONFIRMATION_CODE_ZERO  = '00000'

  # validates_presence_of       :name
  validates_presence_of       :company_id
  validates_presence_of       :start_at, :end_at, :duration
  validates_presence_of       :service_id, :if => :service_required?
  validates_presence_of       :provider_id, :if => :provider_required?
  validates_presence_of       :provider_type, :if => :provider_required?
  validates_presence_of       :customer_id, :if => :customer_required?
  validates_inclusion_of      :mark_as, :in => MARK_AS_TYPES

  before_validation           :calc_and_store_defaults, :make_confirmation_code, :make_uid
  after_create                :grant_company_customer_role, :grant_appointment_manager_role,
                              :expand_recurrence_after_create, :create_appointment_waitlist, :auto_approve
  after_save                  :update_capacity

  # preferences
  serialized_hash             :preferences, {:reminder_customer => '1'}

  has_many                  :appointment_event_category, :dependent => :destroy
  has_many                  :event_categories, :through => :appointment_event_category, :after_add => :after_add_category, :after_remove => :after_remove_category
  
  before_destroy            :before_destroy_callback, :destroy_capacity
  
  # Recurrence constants
  # When creating an appointment from a recurrence, only copy over these attributes into the appointment
  CREATE_APPT_ATTRS        = ["company_id", "service_id", "location_id", "provider_id", "provider_type", "customer_id", "mark_as",
                              "confirmation_code", "uid", "description", "public", "name", "popularity", "url", "capacity"]

  # If any of these attributes change in a recurrence update, we have to re-expand the instances of the recurrence
  REEXPAND_INSTANCES_ATTRS = ["recur_rule", "start_at", "end_at", "duration", "capacity"]

  # These are the attributes which can be used in an update
  UPDATE_APPT_ATTRS        = CREATE_APPT_ATTRS - REEXPAND_INSTANCES_ATTRS
  
  # If any of these attributes change in an appointment update we have to recalculate the capacity
  UPDATE_CAPACITY_ATTRS   = ["start_at", "end_at", "capacity", "provider_id", "provider_type", "location_id", "state"]
  
  acts_as_taggable_on       :tags

  delegate                  :country, :to => '(location or return nil)'
  # delegate                  :state, :to => '(location or return nil)' # conflicts with aasm state machine
  delegate                  :city, :to => '(location or return nil)'
  delegate                  :zip, :to => '(location or return nil)'
  delegate                  :neighborhoods, :to => '(location or return nil)'
  delegate                  :street_address, :to => '(location or return nil)'
  delegate                  :lat, :to => '(location or return nil)'
  delegate                  :lng, :to => '(location or return nil)'

  attr_accessor             :customer_name, :start_date, :start_time, :end_date, :end_time, :force

  def customer_name
    self.customer.name
  end
  
  def customer_name=(new_name)
  end
  
  def start_date
    self.start_at.to_s(:appt_datepicker_date)
  end
  
  def start_date=(new_date)
  end
  
  def end_date
    self.end_at.to_s(:appt_datepicker_date)
  end
  
  def end_date=(new_date)
  end
  
  def start_time
    self.start_at.to_s(:appt_time).downcase
  end

  def start_time=(new_time)
  end

  def end_time
    self.end_at.to_s(:appt_time).downcase
  end

  def end_time=(new_time)
  end

  named_scope :min_popularity,  lambda { |x| {:conditions => ["appointments.popularity >= ?", x] }}

  named_scope :company,         lambda { |o| { :conditions => {:company_id => o.is_a?(Integer) ? o : o.id} }}
  named_scope :service,         lambda { |service| if (service.blank?)
                                                    {}
                                                  else
                                                    {:conditions => {:service_id => service.is_a?(Integer) ? service : service.id}}
                                                  end
                                        }
  named_scope :provider,        lambda { |provider| if (provider.blank?)
                                                    {}
                                                  else
                                                    {:conditions => {:provider_id => provider.id, :provider_type => provider.class.to_s}}
                                                  end
                                        }
  named_scope :no_provider,   { :conditions => {:provider_id => nil, :provider_type => nil} }
  named_scope :customer,      lambda { |o| { :conditions => {:customer_id => o.is_a?(Integer) ? o : o.id} }}

  # Duration greater than or equal to a value. If nil passed in here, no conditions are added
  named_scope :duration_gteq, lambda { |t|  if (t.blank?)
                                              {}
                                            else
                                              { :conditions => ["appointments.duration >= ?", t] }
                                            end
                                     }

  # find future, past appointments, or those before or after a specific datetime
  named_scope :future,        lambda { { :conditions => ["appointments.start_at >= ?", Time.zone.now] } }
  named_scope :past,          lambda { { :conditions => ["appointments.end_at <= ?", Time.zone.now] } }
  named_scope :after,         lambda { |t| { :conditions => ["appointments.start_at > ?", t] } }
  named_scope :after_incl,    lambda { |t| { :conditions => ["appointments.start_at >= ?", t] } }
  named_scope :before,        lambda { |t| { :conditions => ["appointments.start_at < ?", t] } }
  named_scope :before_incl,   lambda { |t| { :conditions => ["appointments.start_at <= ?", t] } }
  
  # find appointments overlapping a time range
  named_scope :overlap,       lambda { |start_at, end_at| { :conditions => ["(appointments.start_at < ? AND end_at > ?) OR (appointments.start_at < ? AND end_at > ?) OR 
                                                                             (appointments.start_at >= ? AND end_at <= ?)", 
                                                                             start_at, start_at, end_at, end_at, start_at, end_at] }}

  # find appointments overlapping a time of day range
  named_scope :time_overlap,  lambda { |time_range| { :conditions => ["(appointments.time_start_at < ? AND appointments.time_end_at > ?) OR 
                                                                       (appointments.time_start_at < ? AND appointments.time_end_at > ?) OR 
                                                                       (appointments.time_start_at >= ? AND appointments.time_end_at <= ?)", 
                                                                       time_range.first, time_range.first, 
                                                                       time_range.last, time_range.last, 
                                                                       time_range.first, time_range.last] }}

  # find appointments by mark_as type
  MARK_AS_TYPES.each                  { |s| named_scope s, :conditions => {:mark_as => s} }
  named_scope :free_work,             { :conditions => ["appointments.mark_as = ? OR appointments.mark_as = ?", FREE, WORK]}
  named_scope :work,                  { :conditions => ["appointments.mark_as = ?", WORK] }
  named_scope :free,                  { :conditions => ["appointments.mark_as = ?", FREE] }

  # find appointments by state is part of the AASM plugin
  # add named scopes for special state queries
  named_scope :not_canceled,          { :conditions => ["appointments.state <> 'canceled'"] }
  
  # find appointments that have no free appointment
  named_scope :orphan,                { :conditions => ["appointments.free_appointment_id is null"] }

  # order by start_at
  named_scope :order_start_at,        {:order => 'appointments.start_at'}
  named_scope :order_start_at_desc,   {:order => 'appointments.start_at desc'}

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
                    { :include => :location, 
                      :conditions => ["appointments.location_id = '?' OR appointments.location_id IS NULL OR appointments.location_id = 0",
                                      location.id] }
                  end
                }
  # specific_location is used for narrow searches, where a search for appointments in Chicago includes only those appointments assigned to
  # Chicago. A search for appointments assigned to anywhere includes only those appointments - not those assigned to Chicago, for example.
  named_scope :specific_location,
                lambda { |location|
                  # If the request is for any location, we look for exactly that
                  if (location.nil? || location.id == 0 || location.id.blank? )
                    { :include => :location, :conditions => ["appointments.location_id IS NULL OR appointments.location_id = 0"] }
                  else
                    # If a location is specified, we accept appointments with this location only - we do not include Anywhere
                    { :include => :location, :conditions => ["appointments.location_id = '?'", location.id] }
                  end
                }
  
  named_scope :public,                    { :conditions => "appointments.public = TRUE" }
  named_scope :private,                   { :conditions => "appointments.public = FALSE" }
  
  named_scope :recurring,                 { :conditions => ["appointments.recur_rule IS NOT NULL AND appointments.recur_rule != ''"] }
  named_scope :not_recurring,             { :conditions => ["appointments.recur_rule IS NULL OR appointments.recur_rule = ''"] }
  named_scope :recurrence_instances,      { :conditions => ["appointments.recur_parent_id IS NOT NULL"]}
  named_scope :not_recurrence_instances,  { :conditions => ["appointments.recur_parent_id IS NULL"] }

  named_scope :in_recurrence,             lambda { |recur_parent_id|
                                            { 
                                            :joins => "inner join appointments free_appointments on (free_appointments.id = appointments.free_appointment_id)",
                                            :conditions => ["(free_appointments.id = ? or free_appointments.recur_parent_id = ?)", recur_parent_id, recur_parent_id],
                                            :select => "appointments.*"
                                            }
                                          }

  named_scope :order_byid,      {:order => 'appointments.id'}
  named_scope :order_byid_desc, {:order => 'appointments.id desc'}

  # valid when values
  WHEN_TODAY                = 'today'
  WHEN_TOMORROW             = 'tomorrow'
  WHEN_7_DAYS               = 'next 7 days'
  WHEN_THIS_WEEK            = 'this week'
  WHEN_NEXT_WEEK            = 'next week'
  WHEN_NEXT_2WEEKS          = 'next 2 weeks'
  WHEN_PAST_WEEK            = 'past week'
  WHEN_THIS_MONTH           = 'this month'
  WHEN_NEXT_MONTH           = 'next month'

  WHENS                     = [WHEN_TODAY, WHEN_TOMORROW, WHEN_THIS_WEEK, WHEN_NEXT_WEEK, 'later']
  WHEN_WEEKS                = [WHEN_NEXT_WEEK, WHEN_NEXT_2WEEKS, 'later']
  WHENS_EXTENDED            = [WHEN_TODAY, WHEN_TOMORROW, WHEN_THIS_WEEK, WHEN_NEXT_WEEK, WHEN_NEXT_2WEEKS, 'next 4 weeks', WHEN_THIS_MONTH, 'later']
  WHENS_PAST                = [WHEN_PAST_WEEK, 'past 2 weeks', 'past month']
  
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


  # List the states in which capacity is used, and in which capacity is unused
  USED_CAPACITY_STATES   = ["confirmed", "noshow", "completed"]
  UNUSED_CAPACITY_STATES = ["unapproved", "canceled"]


  # BEGIN acts_as_state_machine
  # If you change these states, you must also change the USED_CAPACITY_STATES & UNUSED_CAPACITY_STATES variables above
  # They will have an impact in the update_capacity filter
  include AASM
  
  aasm_column           :state
  aasm_initial_state    :unapproved
  aasm_state            :unapproved
  aasm_state            :confirmed
  aasm_state            :noshow
  aasm_state            :completed
  aasm_state            :canceled
  
  aasm_event :approve do
    transitions :to => :confirmed, :from => [:unapproved]
  end

  aasm_event :complete do
    transitions :to => :completed, :from => [:confirmed, :noshow] # very flexible about transitions
  end

  aasm_event :noshow do
    transitions :to => :noshow, :from => [:confirmed, :completed]
  end

  aasm_event :cancel do
    transitions :to => :canceled, :from => [:confirmed, :completed, :noshow]
  end
  # END acts_as_state_machine

  def self.aasm_states_with_all
    ['all', 'confirmed', 'noshow', 'completed', 'canceled']
  end

  def self.aasm_states_for_select_with_all
    # remove 'unapproved' state
    [['All', 'all']] + Appointment.aasm_states_for_select.select{ |state_cap, state| state != 'unapproved' }
  end

  # Sphinx index
  define_index do
    indexes name, :as => :name
    indexes location.street_address, :as => :address
    has start_at, :as => :start_at
    has popularity, :type => :integer, :as => :popularity
    has location_id, :type => :integer, :as => :events, :facet => true
    # locality attributes, all faceted
    has location.country_id, :type => :integer, :as => :country_id, :facet => true
    has location.state_id, :type => :integer, :as => :state_id, :facet => true
    has location.city_id, :type => :integer, :as => :city_id, :facet => true
    has location.zip_id, :type => :integer, :as => :zip_id, :facet => true
    has location.neighborhoods(:id), :as => :neighborhood_ids, :facet => true
    # event categories
    has event_categories(:id), :as => :event_category_ids, :facet => true
    # event tags, for appointment and appointment recurrence parent (if there is one)
    indexes tags.name, :as => :tags
    has tags(:id), :as => :tag_ids, :facet => true
    # SK: we get an ambiguous error here, so comment it out for now
    # indexes recur_parent.tags.name, :as => :recur_tags
    # has recur_parent.tags(:id), :as => :recur_tag_ids, :facet => true
    # only index public appointments
    where "appointments.public = TRUE"
  end

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

  def validate
    if self.when == :error
      errors.add_to_base("When is invalid")
    end

    if self.time == :error
      errors.add_to_base("Time is invalid")
    end
    
    if self.start_at and self.end_at
      # start_at must be before end_at
      if !(start_at < end_at)
        errors.add_to_base("Appointment must start before it ends")
      end
      
      if ((self.end_at.in_time_zone - self.start_at.in_time_zone).to_i != self.duration)
        errors.add_to_base("Appointment duration is incorrect")
      end
    else
      errors.add_to_base("Appointment must have both start and end time")
    end
    
    if self.provider and self.company
      # provider must belong to this company
      if !self.company.has_provider?(self.provider)
        errors.add_to_base("Provider is not associated with this company")
      end
    end
    
    if self.service
      # service must be provided by this company
      if !self.service.company == self.company
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
    self.start_at   = time_range.start_at.utc
    self.end_at     = time_range.end_at.utc
  end
  
  def time_range
    Range.new(time_start_at, time_end_at)
  end

  # Assign a location. Don't assign if no location specified, or if Location.anywhere is specified (id == 0)
  def location=(new_loc)
    self.location_id = new_loc.id unless (new_loc.id = 0)
  end
  # END: virtual attributes
  
  # allow assignment of customer attributes when creating an appointment
  # will create a new customer if and only if the email field is unique
  def customer_attributes=(customer_attributes)
    self.customer = User.find_by_email(customer_attributes["email"]) || self.create_customer(customer_attributes)
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
  #  - state must not be 'confirmed' or 'completed' # SK not sure about this anymore
  def conflicts
    @conflicts ||= self.company.appointments.free_work.provider(provider).overlap(start_at, end_at)
  end

  # Conflicting free time conflicts
  def free_conflicts
    @conflicts ||= self.company.appointments.free.not_canceled.provider(provider).overlap(start_at, end_at)
  end

  # Conflicting work time conflicts, not including canceled work appointments
  def work_conflicts
    @conflicts ||= self.company.appointments.work.not_canceled.provider(provider).overlap(start_at, end_at)
  end

  # Affected capacity slots include those overlapping or touching a time range, not necessarily covering all of it
  def affected_capacity_slots
    self.company.capacity_slots.provider(self.provider).overlap_incl(self.start_at, self.end_at).duration_gteq(self.duration).order_capacity_desc
  end

  # returns true if this appointment conflicts with any other
  def conflicts?
    self.conflicts.count > 0
  end
  
  def free_conflicts?
    self.free_conflicts.count > 0
  end

  def free?
    self.mark_as == FREE
  end

  def work?
    self.mark_as == WORK
  end

  def vacation?
    self.mark_as == VACATION
  end
  
  def future?
    self.start_at > Time.zone.now
  end

  # return the collection of waitlist appointments that overlap with this free appointment
  def waitlist
    # check that this is a free appointment
    return [] if self.mark_as != FREE
    # find wait appointments that overlap in both date and time ranges
    time_range  = self.time_range
    @waitlist ||= company.waitlists.date_overlap(start_at, end_at).time_overlap(time_range.first, time_range.last).provider(provider)
  end
  
  def public?
    self.public
  end
  
  def private?
    !self.public
  end

  # Is this appointment an instance of a recurrence (does not include the parent instance)
  # Should have a recurrence parent
  def recurrence_instance?
    !self.recur_parent.blank?
  end

  # Is this appointment the parent of a recurrence
  # Should have a recurrence rule and no recurrence parent
  def recurrence_parent?
    !self.recur_rule.blank? && self.recur_parent.blank?
  end

  # Is this appointment a member of a recurrence - either instance or parent
  def recurrence?
    recurrence_instance? || recurrence_parent?
  end

  # If this appointment is an instance of a recurrence, returns the recurrence parent instance
  def recurrence_parent
    if (recurrence_parent?)
      # If this instance is a recurrence parent then it is its own parent
      self
    else
      # If it has no recurrence parent this will be nil, else the recurrence parent
      self.recur_parent
    end
  end

  def popular!
    # popularity value decreases the further away it is
    max_pop_value = 100
    days_from_now = (self.start_at > Time.now.beginning_of_day.utc) ? (self.start_at - Time.now) / 86400 : max_pop_value
    self.update_attribute(:popularity, max_pop_value - days_from_now)
  end

  def unpopular!
    self.update_attribute(:popularity, 0)
  end

  # return the event location's name
  def location_name
    # use the associated location's name
    if !self.location_id.blank?
      self.location.company_name
    else
      ""
    end
  end
  
  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng
    false
  end

  def apply_category_tags!(category)
    return false if category.blank? or category.tags.blank?
    self.tag_list.add(category.tags.split(",")) 
    self.save
  end

  def remove_category_tags!(category)
    return false if category.blank? or category.tags.blank?
    category.tags.split(",").each { |s| self.tag_list.remove(s) }
    self.save
  end
  
  # remove event references
  def before_destroy_callback
    location.appointments.delete(self) if location
  end

  # expand_all_recurrences loops through all recurrences for a single company, and
  # expands them all using the dates provided.
  # Note that these dates are passed through to expand_recurrence. As a result they can all be nil, in which case the sensible
  # thing will happen - i.e. It will start at the end of the parent, or at the expanded_to date, whichever is later, and will
  # continue to the time horizon, assuming that's later than the parent.
  # So, the sensible thing is to call this function with one parameter = the company
  def self.expand_all_recurrences(company, starting = nil, before = nil, count = nil)
    company.appointments.recurring.not_canceled.each do |recur|
      recur.expand_recurrence(starting, before, count)
    end
  end

  #
  # Expand a recurrence from a starting date up to a before date, or a certain number of times
  # If starting is nil, starting will be the recur_expanded_to DateTime, unless it too is blank. In this case, it will
  # be the end time of the recurrence parent.
  # If before is nil, the recurrence will be expanded to Time.zone.now.beginning_of_day + the time horizon
  #
  # So, if you want to do the sensible thing, call the function with no parameters and it will figure it out
  #
  def expand_recurrence(starting = nil, before = nil, count = nil)
    # puts "***** expanding #{self.id}, start_at #{self.start_at.utc}, end_at #{self.end_at.utc}, recur_rule #{self.recur_rule}"
    # puts "starting: #{starting.utc}, before: #{before.utc}"

    # We can only expand recurrence on a recurrence parent.
    return unless recurrence_parent?

    # Make sure we start expanding after the end of the master appointment.
    # Otherwise we will get an instance created on top of the master
    # By default we expand from the the date it has already been expanded to, until the before date
    # If the expanded to date is blank we use the end DateTime of the recurrence parent. Same if the expanded_to date is corrupt (< self.end_at)
    if starting.blank? || (starting < self.end_at)
      starting = (self.recur_expanded_to.blank? || (self.recur_expanded_to < self.end_at)) ? self.end_at : self.recur_expanded_to
    end
    
    # By default the before time is the beginning of today + the time horizon
    if before.blank? || (before < self.end_at)
      time_horizon = self.company.preferences[:time_horizon].to_i
      before = Time.zone.now.beginning_of_day + time_horizon
      # If the time horizon added to the beginning of today results in a time that is invalid (earlier than the end of the recurrence parent) we return.
      # We also return if we've already expanded the recurrence past the before before time - i.e. if the starting time is later than the before time
      if (before <= self.end_at) || (before <= starting)
        return
      end
    end

    # Create a RiCal calendar with our recurring appointments
    ri_ev = nil
    ri_ev = RiCal.Event do |ev|
      ev.dtstart = self.start_at
      ev.dtend =self.end_at
      ev.rrule = self.recur_rule
    end
    args = {:starting => starting, :before => before}
    args = args.merge({:count => count}) unless count.nil?

    ri_ev.occurrences(args).each do |ri_occurrence|

      begin
        
        # Create an appointment 
        # We extract the attributes we want to copy over into the new appointment instances
        attrs = self.attributes.inject(Hash.new){|h, (k,v)| CREATE_APPT_ATTRS.include?(k) ? h.merge(k => v) : h }

        # Then we add the attributes we get from the recurrence above, and the refence to the recurrence
        attrs = attrs.merge({:start_at => ri_occurrence.dtstart.in_time_zone, :end_at => ri_occurrence.dtend.in_time_zone,
                              :duration => (ri_occurrence.dtend.in_time_zone - ri_occurrence.dtstart.in_time_zone).to_i,
                              :recur_parent_id => self.id, :location_id => self.location_id})

        # puts "***** creating instance: start_at: #{ri_occurrence.dtstart.to_time.utc}, end_at: #{ri_occurrence.dtend.to_time.utc}"
        a = Appointment.new(attrs)

        # Make sure to check validity before free_conflicts - validity check ensures start_at, end_at and duration are all in line
        Appointment.transaction do
          a.save
          raise AppointmentInvalid, a.errors.full_messages unless a.valid?
        end

      rescue Exception => e

        # TODO - need to communicate to the user that we had a failure
        # Nothing to do here yet. Will need to flag the issue by adding something to the parent record.
        puts "Exception expanding recurrence: " + e.message
        puts "Need to send message to user here"

      end
    end

    # Only update recur_expanded_to if before is later than the existing value
    if (self.recur_expanded_to.blank?) || (before > self.recur_expanded_to)
      self.update_attribute(:recur_expanded_to, before)
    end
    self.recur_instances
  end

  #
  # update recurrence must be called explicitly with an array of changed attributes and a hash of the changes (:key => new_value)
  # Note that the attr_changes parameter is not the same as the .changes result from the dirty parameters code - it does not include the old value
  # If you want to use the dirty attributes hash, then chnage the h.merge(k => v) below to read h.merge(k => v[1])
  #
  def update_recurrence(attr_changed, attr_changes)

    # Check if this is a recurrence parent
    if self.recurrence_parent?
      # Check if any of the attributes changed that cause us to reexpand the recurring instances
      if ((attr_changed & REEXPAND_INSTANCES_ATTRS).size > 0)

        # We need to rebuild all the instances
        self.recur_instances.each do |a| 
          # Destroy the recurrence instance
          a.destroy
        end
        # Clear the expanded_to date
        self.update_attribute(:recur_expanded_to, nil)
        
        # Queue the request to expand. Use the default expand parameters
        self.send_later(:expand_recurrence)

      elsif ((attr_changed & UPDATE_APPT_ATTRS).size > 0)
        # We can update the existing instances
        # Build a hash of the changes, take out any attributes we don't want to update
        instance_updates = attr_changes.inject(Hash.new){|h, (k,v)| UPDATE_APPT_ATTRS.include?(k.to_s) ? h.merge(k => v) : h }
        self.recur_instances.each { |a| a.update_attributes(instance_updates) }
      end
    end
  end

  protected

  def after_remove_tagging(tag)
    Appointment.decrement_counter(:taggings_count, id)
    Tag.decrement_counter(:taggings_count, tag.id)
  end

  def after_add_category(category)
    return if category.tags.blank?
    # add category tags and save object
    apply_category_tags!(category)
    # increment counter cache
    EventCategory.increment_counter(:events_count, category.id)
  end
  
  def after_remove_category(category)
    return if category.tags.blank?
    # remove category tags and save object
    remove_category_tags!(category)
    # decrement counter cache
    EventCategory.decrement_counter(:events_count, category.id)
  end
  
  # service is required for all work appointments
  def service_required?
    return true if (work? || (free? && private?))
    false
  end

  # providers are required for all work appointments
  def provider_required?
    return true if (work? || (free? && private?))
    false
  end
  
  # customers are required for work and appointments
  def customer_required?
    # allow work appointments to have the anyone customer
    return false if work? and customer_anyone?
    return true if work?
    false
  end

  def customer_anyone?
    return true if (self.customer and self.customer.id == User.anyone.id)
    false
  end

  def make_confirmation_code
    unless self.confirmation_code
      # create a random string
      possible_values         = Array('A'..'Z') + Array(0..9)
      code_length             = 5
      self.confirmation_code  = (0...code_length).map{ possible_values[rand(possible_values.size)]}.join
    end
  end
  
  # iCalendar uid attribute
  def make_uid
    if self.uid.blank?
      # Make sure we have a confirmation code
      if self.confirmation_code.blank?
        make_confirmation_code
      end
      # use a constant string
      self.uid = "#{Time.zone.now.to_s(:appt_schedule)}-#{self.confirmation_code}@walnutindustries.com"
    end
  end

  # add 'company customer' role to a work appointment's customer
  def grant_company_customer_role
    return if ![WORK].include?(self.mark_as) or self.customer.blank?
    self.customer.grant_role('company customer', self.company) unless self.customer.has_role?('company customer', self.company)
  end
  
  # add 'appointment manager' role to work appointments
  def grant_appointment_manager_role
    return if ![WORK].include?(self.mark_as)

    if self.customer
      self.customer.grant_role('appointment manager', self) unless self.customer.has_role?('appointment manager', self)
    end

    if self.provider && (self.provider.class == User)
      self.provider.grant_role('appointment manager', self) unless self.provider.has_role?('appointment manager', self)
    end
  end
  
  #
  # calc_and_store_defaults
  #
  # Ensures basic values like mark_as, time and when are set OK
  # Make start_at and end_at times from the start_date / start_time and end_date / end_time combination, if appropriate
  # Set the capacity if required
  #
  def calc_and_store_defaults

    #
    # First some basic defaults for mark_as, when and time
    #

    # initialize mark_as if its blank and we have a service
    if self.mark_as.blank? and !self.service.blank?
      self.mark_as_will_change!
      self.mark_as = self.service.mark_as
    end

    # initialize when, time attributes with default values
    if self.when.blank?
      self.when_will_change!
      self.when = ''
    end

    if self.time.blank?
      self.time_will_change!
      self.time = ''
    end

    #
    # Fix up the duration and end_at values
    #
    
    # If the duration changed, we adjust end_at
    # Note that if both duration and end_at change, duration wins
    if self.changed.include?("duration")
      self.end_at_will_change!
      self.end_at = self.start_at.in_time_zone + self.duration
    elsif self.changed.include?("start_at") || self.changed.include?("end_at")
      # If start_at or end_at changed we adjust the duration
      self.duration_will_change!
      self.duration = (self.end_at.in_time_zone - self.start_at.in_time_zone).to_i
    end
    
    # Make sure the time_start_at and time_end_at values are calculated correctly
    if !self.start_at.blank?
      self.time_start_at_will_change!
      self.time_start_at = (self.start_at.utc.hour.hours + self.start_at.utc.min.minutes + self.start_at.utc.sec.seconds).to_i
      self.time_start_at = (self.time_start_at % 24.hours).to_i unless (self.time_start_at < 24.hours)
      if !self.duration.blank?
        self.time_end_at_will_change!
        self.time_end_at   = (self.time_start_at.to_i + self.duration.to_i).to_i
        self.time_end_at   = (self.time_end_at % 24.hours).to_i unless (self.time_end_at < 24.hours)
      end
    end

    # Make sure the capacity is set, from the service if possible
    if self.capacity.blank?
      if self.service.blank?
        self.capacity = 1
      else
        self.capacity = self.service.capacity
      end
    end

    # Continue the filter chain
    true

  end
  
  # The appointment is going away. Destroy its capacity
  # Force this to happen. If we're here, we're here..
  # If the attributes of the appointment are incorrect for some reason we don't try to fix it. This shouldn't happen in normal operation
  # (it happens when tearing down the demos because the resources / users may go away before the appointments)
  def destroy_capacity

    # Don't try to destroy capacity for an appointment that's already canceled, or that doesn't have the necessary attributes
    return true if (self.canceled? || self.company.blank? || self.provider.blank?)
    CapacitySlot.transaction do
      CapacitySlot.change_capacity(self.company, self.location, self.provider, self.start_at, self.end_at, -self.capacity, :force => true)
    end

    # Continue the filter chain
    true
  end

  def update_capacity

    # Determine if we need to update the capacity slot or not
    if ((self.changed & UPDATE_CAPACITY_ATTRS).size == 0)
      # None of the relevant attributes were changed. We don't process this change
      return true
    end

    # Figure out the capacity changes to undo the old capacity and carry out the new
    # Basically a sign difference between work and free appointments
    if self.work?
      capacity_undo_old = self.capacity_was
      capacity_do_new = -self.capacity
    elsif (self.free? && !self.public)
      capacity_undo_old = -self.capacity_was
      capacity_do_new = self.capacity
    else
      # It's not a work appointment and it's not a free private appointment
      # Might be a public appointment. Regardless, we're not going to process it
      return true
    end
    
    # Get the old associations (the new associations are available in the usual way)
    if (self.location_id_was == 0 || self.location_id_was.blank?)
      location_was = Location.anywhere
    else
      location_was = Location.find(self.location_id_was)
    end

    if self.provider_type_was == 'User'
      provider_was = User.find(self.provider_id_was)
    elsif self.provider_type_was == 'Resource'
      provider_was = Resource.find(self.provider_id_was)
    end

    # We don't undo the old state if there was no old state - essentially if any of the old fields are blank, or if the old state is unapproved or canceled
    # If so, we couldn't / shouldn't have processed capacity for it previously, so we don't try to undo that
    dont_undo_old = provider_was.blank? || self.start_at_was.blank? || self.end_at_was.blank? || self.capacity_was.blank? || (self.state_was.blank?) || self.new_record? ||
                      (UNUSED_CAPACITY_STATES.include?(self.state_was))

    # If the new appointment state is either unapproved or canceled, or for some reason the new data is invalid, don't try to process the new values.
    dont_do_new   = self.provider.blank? || self.start_at.blank? || self.end_at.blank? || self.capacity.blank? || (self.state.blank?) || 
                      (UNUSED_CAPACITY_STATES.include?(self.state))
                      
    # If the only thing that changed is the state, and the change in state doesn't cause a change in capacity, we don't change capacity
    # This happens, for example, if a confirmed appointment is completed or a noshow - any of these states consume capacity, so the capacity doesn't change
    # Similarly, if the appointment goes from unapproved to canceled, neither state consumes capacity and so no change is made
    if (((self.changed & UPDATE_CAPACITY_ATTRS) == ["state"]) &&
        (
          ((USED_CAPACITY_STATES.include?(self.state_was)) && (USED_CAPACITY_STATES.include?(self.state))) ||
          ((UNUSED_CAPACITY_STATES.include?(self.state_was)) && (UNUSED_CAPACITY_STATES.include?(self.state)))
        )
       )
        dont_undo_old = dont_do_new = true
    end

    CapacitySlot.transaction do
      
      # Always add capacity before taking it away. This is intended to avoid a situation where a fleeting lack of capacity causes an issue
      if capacity_undo_old > capacity_do_new

        # We undo the old capacity for the appointment
        enough_capacity = CapacitySlot.change_capacity(self.company, location_was, provider_was, self.start_at_was, self.end_at_was,
                                                       capacity_undo_old, :force => self.force) unless dont_undo_old

        # Now carry out the new capacity change
        # If this user has rights, we force it. If not, we don't
        enough_capacity &= CapacitySlot.change_capacity(self.company, self.location, self.provider, self.start_at, self.end_at,
                                                        capacity_do_new, :force => self.force) unless dont_do_new
                                                        
      else

        # We create new capacity
        # If this user has rights, we force it. If not, we don't
        enough_capacity &= CapacitySlot.change_capacity(self.company, self.location, self.provider, self.start_at, self.end_at,
                                                        capacity_do_new, :force => self.force) unless dont_do_new
                                
        # Then remove old capacity
        # We undo the old capacity for the appointment
        enough_capacity = CapacitySlot.change_capacity(self.company, location_was, provider_was, self.start_at_was, self.end_at_was,
                                                       capacity_undo_old, :force => self.force) unless dont_undo_old

      end

      
      # If the update was unsuccessful, we rollback and stop the filter chain
    end
    
    # Clear the force attribute - make sure this object's force value isn't cached and used again incorrectly
    self.force = false
    
    # Continue the filter chain
    true

  end

  # expand recurrence appointments by some default value
  def expand_recurrence_after_create
    return unless recurrence_parent?
    self.send_later(:expand_recurrence)
  end

  def create_appointment_waitlist
    if RAILS_ENV == 'development'
      AppointmentWaitlist.create_waitlist(self)
    end
  end

  # after create callback to automatically approve appointments
  def auto_approve
    self.approve!
  end

end
