class DateRange
  attr_accessor :name, :start_at, :end_at, :days
  cattr_accessor :errors
  
  # extend ActiveRecord so we can use the Errors module
  extend ActiveRecord

  # include enumerable mixin which requires an 'each' method
  include Enumerable
  
  def initialize(options={})
    @name             = options[:name]
    @name_with_dates  = options[:name_with_dates]
    
    if @name == 'error'
      # create error object
      @error  = true
      @errors = ActiveRecord::Errors.new(self)
      @errors.add_to_base("When is invalid")
      return
    end
    
    @start_at = options[:start_at] if options[:start_at]
    @end_at   = options[:end_at] if options[:end_at]
    
    if @start_at and @end_at
      # if end_at ends at 59 minutes and 59 seconds, add 1 second to make sure the days calculation is correct
      seconds   = (@end_at - @start_at).to_i
      seconds   += 1 if @end_at.min == 59 and @end_at.sec == 59
      # convert seconds to days
      @days     = seconds / (60 * 60 * 24)
    else
      @days     = 0
    end
    
    # initialize enumerable param
    @index = 0
  end
  
  def valid?
    !@error
  end

  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end
  
  def each
    # range is inclusive
    Range.new(0, @days-1).each do |i|
      yield @start_at + i.days
    end
  end
  
  # options
  #  - :with_dates => true|false; if true, return the name with dates, otherwise use the basic name
  def name(options={})
    if options[:with_dates] == true
      @name_with_dates
    else
      @name
    end
  end
  
  def self.today
    Time.today.utc
  end
  
  # return start_at and end_at dates as a date range (e.g. "20090101..20090201")
  def to_url_param(options={})
    case options[:for]
    when :start_date
      @start_at.to_s(:appt_schedule_day)
    when :end_date
      @end_at.to_s(:appt_schedule_day)
    else
      "#{@start_at.to_s(:appt_schedule_day)}..#{@end_at.to_s(:appt_schedule_day)}"
    end
  end
  
  # parse when string into a valid date range
  # options:
  #  - start_on  => [0..6], day of week to start calendar on, 0 is sunday, defaults to start_at
  #  - end_on    => [0..6], day of week to end calendar on, 0 is sunday, defaults to end_at
  #  - include   => :today, add today if utc day <> local time day 
  def self.parse_when(s, options={})
    # initialize now to utc time
    now = Time.now.utc
    
    if (m = s.match(/next (\d{1}) week/)) # e.g. 'next 3 weeks', 'next 1 week'
      # use [today, today + n weeks - 1.second], always end on sunday at midnight
      n         = m[1].to_i
      start_at  = now.beginning_of_day
      end_at    = start_at + n.weeks - 1.second
    else
      case s
      when 'today'
        # end at midnight today
        start_at  = now.beginning_of_day
        end_at    = start_at.end_of_day
      when 'tomorrow'
        # end at midnight tomorrow
        start_at  = now.tomorrow.beginning_of_day
        end_at    = start_at.end_of_day
      when 'this week'
        # ends on sunday at midnight
        end_at    = now.end_of_week
        start_at  = now.beginning_of_day
        if options[:include] == :today
          start_at -= 1.day if now.yday > Time.now.yday
        end
      when 'next week'
        # next week starts on monday, and end on sunday at midnight
        start_at  = now.next_week
        end_at    = start_at.end_of_week
      when 'later'
        # should start after 'next week', and continue for 2 weeks, ending on sunday at midnight
        start_at  = now.next_week + 1.week
        end_at    = (start_at + 1.week).end_of_week
      when 'past week'
        end_at    = now.end_of_day
        start_at  = end_at - 1.week + 1.second
      when 'past 2 weeks'
        end_at    = now.end_of_day
        start_at  = end_at - 2.weeks + 1.second
      when 'past month'
        end_at    = now.end_of_day
        start_at  = end_at - 1.month + 1.second
      else
        return DateRange.new(Hash[:name => 'error'])
      end
    end
    
    # adjust calendar based on start_on and end_on days
    start_at  = adjust_start_day_to_start_on(start_at, options)
    end_at    = adjust_end_day_to_end_on(end_at, options)
      
    range     = "#{start_at.to_s(:appt_short_month_day_year)} - #{end_at.to_s(:appt_short_month_day_year)}"
    name      = "#{s.titleize}"
    DateRange.new(Hash[:name => name, :name_with_dates => "#{name}: #{range}", :start_at => start_at, :end_at => end_at])
  end
  
  # parse start, end dates - e.g. "20090101", defaults to end date inclusive
  # options:
  #   - inclusive => true|false, if true include end date in range, default is true
  #   - start_on  => [0..6], day of week to start calendar on, 0 is sunday, defaults to start_at.wday
  #   - end_on    => [0..6], day of week to end calendar on, 0 is sunday, defaults to end_at.wday
  def self.parse_range(start_date, end_date, options={})
    # parse options
    inclusive = options.has_key?(:inclusive) ? options[:inclusive] : true
    
    # build start_at, end_at times in local time format
    start_at  = Time.parse(start_date).beginning_of_day
    end_at    = Time.parse(end_date).beginning_of_day

    # build name from start_at, end_at times
    name      = "#{start_at.to_s(:appt_short_month_day_year)} - #{end_at.to_s(:appt_short_month_day_year)}"
    
    if inclusive
      # include the last day by adjusting to the end of the day
      end_at = end_at.end_of_day
    end

    # adjust calendar based on start_on, end_on day
    start_at  = options[:start_on] ? adjust_start_day_to_start_on(start_at, options) : start_at
    end_at    = options[:end_on] ? adjust_end_day_to_end_on(end_at, options) : end_at
    
    DateRange.new(Hash[:name => name, :name_with_dates => name, :start_at => start_at, :end_at => end_at])
  end
    
  protected
  
  # adjust start_at based on start_on day
  def self.adjust_start_day_to_start_on(start_at, options)
    start_on = options[:start_on] || start_at.wday
    
    if start_on != start_at.wday
      # need to show x days before start_at to start on the correct day
      subtract_days = start_at.wday > start_on ? start_at.wday - start_on : 7 - (start_on - start_at.wday)
      start_at      -= subtract_days.days
    end
    
    start_at
  end
  
  # adjust end_at based on end_on day
  def self.adjust_end_day_to_end_on(end_at, options)
    # if end_on was specified, adjust it 1 day because we really want the beginning of the next day
    end_on = options[:end_on] ? options[:end_on] : end_at.wday
    
    if end_on != end_at.wday
      # add x days if the end on day is greater than the current day of the week, always end at midnight the previous day
      add_days    = end_on > end_at.wday ? end_on - end_at.wday + 1 : 7 - (end_at.wday - end_on)
      end_at     += add_days.days - 1.second
    end
    
    end_at
  end
end