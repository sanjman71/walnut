# Builds a time range within a given day. This is converted to UTC.
class TimeRange
  attr_accessor :day, :end_day, :start_at, :end_at, :duration
  
  # valid day formats
  #  - '20090101'
  #  - note: 'today', 'tomorrow' are unsupported
  # end_day is optional, same format as day. If not provided, assumes end_day is same as day
  #
  # valid start/end time formats
  #  - '0300', '1 pm' 
  #  - '1200', '1230', '12xx' is handled as a special case
  def initialize(options={})
    @day          = options[:day]
    @end_day      = options[:end_day] || @day
    @start_at     = options[:start_at]
    @end_at       = options[:end_at]
    
    if @start_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day and start time to time object
      @start_at = Time.zone.parse("#{@day} #{@start_at}")
    end

    if @start_at.blank? and @day
      # default to beginning of 'day'
      @start_at = Time.zone.parse(@day).beginning_of_day
    end
    
    if @end_at.is_a?(String) and @end_day and @end_day.is_a?(String)
      # convert day and end time to time object
      @end_at = Time.zone.parse("#{@end_day} #{@end_at}")
    end

    if @end_at.blank? and @end_day
      # default to end of 'day'
      @end_at = Time.zone.parse(@end_day).end_of_day + 1.second
    end
    
    @start_at = @start_at.utc
    @end_at = @end_at.utc
    
    # initialize duration (in minutes)
    @duration = (@end_at.to_i - @start_at.to_i) / 60
  end
    
  def to_s
    @day
  end
  
  # time_start_at and time_end_at are expressed in seconds, in UTC time
  def time_start_at
    @time_start_at ||= self.start_at.in_time_zone.hour * 3600 + self.start_at.in_time_zone.min * 60
  end
  
  def time_end_at
    @time_end_at ||= self.end_at.in_time_zone.hour * 3600 + self.end_at.in_time_zone.min * 60
  end
  
  def time_start_at_utc
    @time_start_at_utc ||= self.start_at.utc.hour * 3600 + self.start_at.utc.min * 60
  end
  
  def time_end_at_utc
    @time_end_at_utc ||= self.end_at.utc.hour * 3600 + self.end_at.utc.min * 60
  end
end