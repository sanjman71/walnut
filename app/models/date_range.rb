class DateRange
  attr_accessor :name, :start_at, :end_at, :days, :range_type
  cattr_accessor :errors
  
  RANGE_TYPES = %w(daily weekly monthly)
  
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
      # adjust calendar based on start_on and end_on days
      @start_at  = DateRange.adjust_start_day_to_start_on(@start_at, options)
      @end_at    = DateRange.adjust_end_day_to_end_on(@end_at, options)

      # if end_at ends at 59 minutes and 59 seconds, add 1 second to make sure the days calculation is correct
      seconds   = (@end_at - @start_at).to_i
      seconds   += 1 if @end_at.min == 59 and @end_at.sec == 59
      # convert seconds to days. Use floating point and round to allow for 1 extra or 1 fewer hours at spring fwd / fall back
      @days     = (seconds.to_f / 24.hours).round
    else
      @days     = 0
    end
    
    # initialize enumerable param
    @index = 0
    
    # initialize range type
    @range_type = options[:range_type] || 'none'
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

  # returns true if the daterange includes the specifed date
  def include?(date)
    date >= @start_at and date <= @end_at
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
    Time.zone.today
  end
  
  # return start_at and end_at dates as a date range (e.g. "20090101..20090201")
  # Use default time zone, not UTC
  def to_url_param(options={})
    case options[:for]
    when :start_date
      @start_at.in_time_zone.to_s(:appt_schedule_day)
    when :end_date
      @end_at.in_time_zone.to_s(:appt_schedule_day)
    else
      "#{@start_at.in_time_zone.to_s(:appt_schedule_day)}..#{@end_at.in_time_zone.to_s(:appt_schedule_day)}"
    end
  end
  
  # parse when string into a valid date range
  # options:
  #  - start_date     => day to start date range
  #  - start_week_on  => [0..6], day of week company preference to start calendar on; defaults to monday (1)
  #  - start_on       => [0..6], day of week to start calendar on, 0 is sunday, defaults to start_at
  #  - end_on         => [0..6], day of week to end calendar on, 0 is sunday, defaults to end_at
  #  - include        => :today, add today if utc day <> local time day 
  def self.parse_when(s, options={})
    # initialize now in the current time zone
    now = Time.zone.now

    start_week_on = options[:start_week_on] ? options[:start_week_on].to_i : 1

    if (m = s.match(/next (\d{1,2}) week/)) # e.g. 'next 3 weeks', 'next 1 week', 'next 10 weeks'
      # use [today, today + n weeks til end of week - 1.second], always end on last day of week at midnight
      nweeks    = m[1].to_i
      start_at  = options[:start_date] ? options[:start_date].beginning_of_day : now.beginning_of_day
      if start_at.in_time_zone.wday == start_week_on
        # subtract a week, so we don't extend over n+1 full weeks
        nweeks -= 1
      end
      end_at    = (start_at + nweeks.weeks).end_of_week_starting_on(start_week_on)
      range_type = 'weekly'
    else
      case s
      when 'today'
        # end at midnight today
        start_at  = now.beginning_of_day
        end_at    = start_at.end_of_day
        range_type = 'daily'
      when 'tomorrow'
        # end at midnight tomorrow
        start_at  = now.tomorrow.beginning_of_day
        end_at    = start_at.end_of_day
        range_type = 'daily'
      when 'next 7 days'
        start_at  = now.beginning_of_day
        end_at    = start_at + 7.days
        range_type = 'weekly'
      when 'this week'
        if options[:include] == :today
          start_at  = now.beginning_of_day
        else
          start_at  = now.tomorrow.beginning_of_day
        end
        # ends on last day of week at midnight
        end_at      = now.end_of_week_starting_on(start_week_on)
        range_type  = 'weekly'
      when 'next week'
        if options[:include] == :today
          # next week starts today
          start_at  = now.beginning_of_day
          # use start_week_on to determine end day next week, and add 1 week
          end_at    = (start_at + 1.week).end_of_week_starting_on(start_week_on)
        else
          # next week uses start_week_on to determine start day
          start_at  = now.next_week_starting_on(start_week_on)
          # use start_week_on to determine the end day next week
          end_at    = start_at.end_of_week_starting_on(start_week_on)
        end
        range_type = 'weekly'
      when 'later'
        # should start after 'next 2 weeks', and continue for 2 weeks, ending on the last day at midnight
        start_at  = now.next_week_starting_on(start_week_on) + 2.weeks
        end_at    = (start_at + 1.week).end_of_week_starting_on(start_week_on)
        range_type = 'weekly'
      when 'this month'
        end_at    = now.end_of_month
        if options[:include] == :today
          start_at  = now.beginning_of_day
        else
          start_at  = now.tomorrow.beginning_of_day
        end
        range_type = 'monthly'
      when 'next month'
        end_at    = now.end_of_month
        if options[:include] == :today
          start_at  = now.beginning_of_day
        else
          start_at  = now.tomorrow.beginning_of_day
        end
        range_type = 'monthly'
      when 'past week'
        end_at    = now.end_of_day
        start_at  = end_at - 1.week + 1.second
        range_type = 'weekly'
      when 'past 2 weeks'
        end_at    = now.end_of_day
        start_at  = end_at - 2.weeks + 1.second
        range_type = 'weekly'
      when 'past month'
        end_at    = now.end_of_day
        start_at  = end_at - 1.month + 1.second
        range_type = 'monthly'
      else
        return DateRange.new(Hash[:name => 'error'])
      end
    end

    # adjust calendar based on start_on and end_on days
    start_at  = adjust_start_day_to_start_on(start_at, options)
    end_at    = adjust_end_day_to_end_on(end_at, options)

    # convert times to UTC
    start_at  = start_at.utc
    end_at    = end_at.utc

    if (start_at.in_time_zone.to_s(:appt_short_month_day_year) == end_at.in_time_zone.to_s(:appt_short_month_day_year))
      range   = start_at.in_time_zone.to_s(:appt_short_month_day_year)
    else
      range   = "#{start_at.in_time_zone.to_s(:appt_short_month_day_year)} - #{end_at.in_time_zone.to_s(:appt_short_month_day_year)}"
    end
    name      = "#{s.titleize}"
    DateRange.new(Hash[:name => name, :name_with_dates => "#{name}: #{range}", :start_at => start_at, :end_at => end_at, :range_type => range_type])
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
    start_at  = Time.zone.parse(start_date).beginning_of_day
    end_at    = Time.zone.parse(end_date).beginning_of_day

    # build name from start_at, end_at times
    name      = "#{start_at.to_s(:appt_short_month_day_year)} - #{end_at.to_s(:appt_short_month_day_year)}"
    
    if inclusive
      # include the last day by adjusting to the end of the day
      end_at = end_at.end_of_day
    end

    # adjust calendar based on start_on and end_on days
    start_at  = adjust_start_day_to_start_on(start_at, options)
    end_at    = adjust_end_day_to_end_on(end_at, options)
    
    DateRange.new(Hash[:name => name, :name_with_dates => name, :start_at => start_at, :end_at => end_at, :range_type => 'none'])
  end
  
  def self.parse_range_type(start_date, range_type, options={})
    # build start_at, end_at times in local time format
    start_at  = Time.zone.parse(start_date).beginning_of_day
    case range_type
    when 'daily'
      end_at     = start_at.end_of_day
    when 'weekly'
      end_at     = start_at + 1.week - 1.second
    when 'monthly'
      end_at     = start_at + 1.month - 1.second
    end

    # build name from start_at, end_at times
    name = "#{range_type.titleize} starting on #{start_at.to_s(:appt_short_month_day_year)}"
    
    # adjust calendar based on start_on and end_on days
    start_at  = adjust_start_day_to_start_on(start_at, options)
    end_at    = adjust_end_day_to_end_on(end_at, options)
    
    DateRange.new(Hash[:name => name, :name_with_dates => name, :start_at => start_at, :end_at => end_at, :range_type => range_type])
  end
    
  # adjust start_at based on start_on day
  def self.adjust_start_day_to_start_on(start_at, options)
    if (start_on = options[:start_on]) && (start_on != start_at.in_time_zone.wday)
      # need to show x days before start_at to start on the correct day
      subtract_days = start_at.in_time_zone.wday > start_on ? start_at.in_time_zone.wday - start_on : 7 - (start_on - start_at.in_time_zone.wday)
      start_at      -= subtract_days.days
    end
    start_at
  end
  
  # adjust end_at based on end_on day
  def self.adjust_end_day_to_end_on(end_at, options)
    # if end_on was specified, use it.
    if (end_on = options[:end_on]) && (end_on != end_at.in_time_zone.wday)
      # add x days if the end on day is greater than the current day of the week, always end at midnight the previous day
      add_days    = end_on > end_at.in_time_zone.wday ? end_on - end_at.in_time_zone.wday : 7 - (end_at.in_time_zone.wday - end_on)
      end_at     += add_days.days
    end
    
    end_at
  end
  
  # find next date with the specified day of week
  def self.find_next_date(day_of_week)
    # find 2 letter abbreviation, then map to day of week int
    abbrev   = day_of_week.to_s.upcase.slice(0,2)
    @day_int = Recurrence::DAYS_OF_WEEK_INT[abbrev]
    return nil if @day_int.blank?

    self.parse_when('next 7 days').each do |day|
      return day if day.wday == @day_int
    end
  end

end