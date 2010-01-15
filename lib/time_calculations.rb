module ActiveSupport #:nodoc:
  class TimeWithZone #:nodoc:
      
    def next_week_starting_on(day)
      beginning_of_week_starting_on(day).advance(:weeks => 1).change(:hour => 0)
    end

    def beginning_of_week_starting_on(day)
      days_to_week_start_day = (self.wday > day) ? (self.wday - day) : 6 - (day - self.wday)
      (self - days_to_week_start_day.days).midnight
    end

    def end_of_week_starting_on(day)
      days_to_week_end_day = (self.wday >= day) ? 6 - (self.wday - day) : (day - self.wday) - 1
      (self + days_to_week_end_day.days).end_of_day
    end

  end
end