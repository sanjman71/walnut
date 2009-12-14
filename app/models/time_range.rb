# Builds a time range within a given day. This is converted to UTC.
class TimeRange
  attr_accessor :day, :end_day, :start_at, :end_at, :duration
  
  # valid day formats
  #  - '20090101'
  #  - 'today', 'tomorrow' are not valid
  #
  # end_day is optional, and uses the same format as day; defaults to day
  #
  # valid start/end time formats
  #  - '0300', '1 pm' 
  #  - '1200', '1230', '12xx' is handled as a special case
  def initialize(options={})
    @day        = options[:day]
    @end_day    = options[:end_day] || @day
    @start_at   = options[:start_at]
    @end_at     = options[:end_at]
    @duration   = options[:duration]
    
    # Try to make sure we don't have to deal with DateTime values below
    if @start_at.is_a?(DateTime)
      @start_at = @start_at.to_time
    end

    if @end_at.is_a?(DateTime)
      @end_at = @end_at.to_time
    end

    # If I've been given a start time and day, parse these
    if @start_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day and start time to time object
      @start_at = Time.zone.parse("#{@day} #{@start_at}")
    end

    # If I've been given only a start day, start time is start of day
    if @start_at.blank? and @day
      # default to beginning of 'day'
      @start_at = Time.zone.parse(@day).beginning_of_day
    end

    # If I've been given an end time and day, parse these
    if @end_at.is_a?(String) and @end_day and @end_day.is_a?(String)
      # convert day and end time to time object
      @end_at   = Time.zone.parse("#{@end_day} #{@end_at}")
    end

    # If I haven't been given an end time, but I have been given a start time and duration, use these to calc end time
    if @end_at.blank? and !@duration.blank? and !@start_at.blank?
      @end_at   = @start_at + @duration.to_i
    end
    
    # If I don't have an end time, or a start_time + duration, then end_time is the end of whatever day I have
    if @end_at.blank? and @end_day
      # default to end of 'day'
      @end_at   = Time.zone.parse(@end_day).end_of_day + 1.second
    end

    # initialize duration (in seconds) unless the times aren't set. If we were given duration we recalc here anyway, just in case.
    @duration   = (@end_at.to_time - @start_at.to_time).to_i unless (@start_at.blank? || @end_at.blank?)

    # The type of @start_at and @end_at coming into this is usually ActiveSupport::TimeWithZone
    # The conversion to utc results in either a Time or a DateTime object.
    # Subtraction of two DateTime objects results in a very different result than subtraction of two Time objects.
    # This results in bad things happening when calculating duration.
    # Convert start and end times to UTC
    @start_at   = @start_at.utc unless @start_at.blank?
    @end_at     = @end_at.utc unless @end_at.blank?
    
  end
    
  def to_s
    @day
  end
  
  # time_start_at and time_end_at are expressed in seconds, in UTC time
  # time_end_at is calculated as time_start_at + duration
  # As a result, time_end_at may be > 24 hours (86400 seconds). This is useful, as it indicates a slot crossing midnight
  def time_start_at
    @time_start_at ||= nil
    if !self.start_at.blank?
      @time_start_at ||= (self.start_at.in_time_zone.hour.hours + self.start_at.in_time_zone.min.minutes).to_i
      @time_start_at = (@time_start_at % 24.hours).to_i unless (@time_start_at < 24.hours)
    end
    @time_start_at
  end
  
  def time_end_at
    @time_end_at ||= nil
    if !self.duration.blank? && !self.time_start_at.blank?
      @time_end_at ||= (self.time_start_at.to_i + self.duration.to_i).to_i
      @time_end_at = (@time_end_at % 24.hours).to_i unless (@time_end_at < 24.hours)
    end
    @time_end_at
  end
  
  # time_start_at_utc is the UTC start time expressed in seconds
  # Note that this can be > 24 hours. This occurs if the local start time is late enough that the utc start time is earlier
  # For example, a start time of 20:00 hours PST = 04:00 hours UTC. Instead of representing this as 4.hours, we represent it as 28.hours
  # This is important in the following example:
  # We have availability from 1500 - 2200 PST => time_start_at_utc is 15.hours + 8.hours = 23.hours, time_end_at_utc is 30.hours
  # We're searching for a slot from 2000- 2100 PST => time_start_at_utc is 20.hours + 8.hours = 28.hours, time_end_at_uts is 29.hours
  # If we didn't ensure that UTC continued past 24 hours like this, time_start_at_utc would be 0400 or 4.hours, and time_end_at_utc would be 0500 or 5.hours
  # Searching for 28-29 in the space 23-30 works. But searching for 4-5 doesn't work
  def time_start_at_utc
    @time_start_at_utc ||= nil
    if !self.start_at.blank?
      @time_start_at_utc ||= (self.start_at.utc.hour.hours + self.start_at.utc.min.minutes).to_i
      @time_start_at_utc = (@time_start_at_utc % 24.hours).to_i unless (@time_start_at_utc < 24.hours)
    end
    @time_start_at_utc
  end
  
  def time_end_at_utc
    @time_end_at_utc ||= nil
    if !self.duration.blank? && !self.time_start_at_utc.blank?
      @time_end_at_utc ||= (self.time_start_at_utc.to_i + self.duration.to_i).to_i
      @time_end_at_utc = (@time_end_at_utc % 24.hours).to_i unless (@time_end_at_utc < 24.hours)
    end
    @time_end_at_utc
  end
end
