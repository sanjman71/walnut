class WaitlistTimeRange < ActiveRecord::Base
  belongs_to                  :waitlist

  # validates_presence_of       :waitlist_id  # validation is done in a before filter so nested attributes work
  validates_presence_of       :start_date
  validates_presence_of       :end_date
  validates_presence_of       :start_time
  validates_presence_of       :end_time

  named_scope :past,          lambda { { :conditions => ["end_date < ?", Time.zone.now] } }

  def before_create
    unless self.end_date.blank?
      # set end date time to end of day
      self.end_date = self.end_date.end_of_day
    end
    # validate waitlist
    if self.waitlist_id.blank?
      self.errors.add_to_base("Waitlist can't be blank")
      return false
    end
  end
  
  # BEGIN virtual attributes
  def start_time_hours
    case
    when self.start_time.blank?
      nil
    else
      self.start_time.to_i / 3600
    end
  end

  def start_time_hours_ampm
    time = seconds_to_time(self.start_time)
    time.to_s(:appt_time)
  end

  def start_time_hours=(s)
    if s.is_a?(String)
      self.start_time = hours_string_to_seconds(s)
    elsif s.is_a?(Integer)
      self.start_time = s * 3600
    else
      raise Exception, "invalid start time"
    end
  end

  def end_time_hours
    case
    when self.end_time.blank?
      nil
    else
      self.end_time.to_i / 3600
    end
  end

  def end_time_hours_ampm
    time = seconds_to_time(self.end_time)
    time.to_s(:appt_time)
  end

  def end_time_hours=(s)
    if s.is_a?(String)
      self.end_time = hours_string_to_seconds(s)
    elsif s.is_a?(Integer)
      self.end_time = s * 3600
    else
      raise Exception, "invalid end time"
    end
  end
  # END virtual attributes

  protected

  def hours_string_to_seconds(s)
    case
    when s.length == 4 || s.length == 6 # e.g "0930", "093000"
      # create time object in local time zone, and convert to utc
      date  = Time.zone.now.to_s(:appt_schedule_day)
      time  = Time.zone.parse(date + s)
      time.utc.hour * 3600 + time.utc.min * 60
    else
      raise Exception, "invalid time"
    end
  end
  
  def seconds_to_time(s)
    # build time in utc format, then convert to local time zone
    (Time.now.utc.beginning_of_day + s.seconds).in_time_zone
  end
end