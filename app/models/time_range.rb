# Builds a time range within a given day
class TimeRange
  attr_accessor :day, :start_at, :end_at, :duration
  
  # valid day formats
  #  - '20090101'
  #  - note: 'today', 'tomorrow' are unsupported
  # valid start/end time formats
  #  - '0300', '1 pm' 
  #  - '1200', '1230', '12xx' is handled as a special case
  def initialize(options={})
    @day          = options[:day]
    @start_at     = options[:start_at]
    @end_at       = options[:end_at]
    
    if @start_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day and start time to time object
      @start_at = Time.zone.parse("#{@day} #{@start_at}")
    end

    if @start_at.blank? and @day
      # default to beginning of 'day'
      @start_at = Time.parse(@day).beginning_of_day
    end
    
    if @end_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day and end time to time object
      @end_at = Time.zone.parse("#{@day} #{@end_at}")
    end

    if @end_at.blank? and @day
      # default to end of 'day'
      @end_at = Time.parse(@day).end_of_day + 1.second
    end
    
    # initialize duration (in minutes)
    @duration = (@end_at.to_i - @start_at.to_i) / 60
  end
    
  def to_s
    @day
  end
  
end