class CacheKey
  
  # Create cache key for a collection of appointments over a specified daterange
  def self.schedule(daterange, appointments, time_of_day)
    # use daterange start and end dates
    date_key  = "#{daterange.start_at.to_s(:appt_schedule)}:#{daterange.end_at.to_s(:appt_schedule)}"
    date_key  += ":#{time_of_day}" if !time_of_day.blank?
    
    # add appointment info using an md5 hash
    appt_keys = Digest::MD5.hexdigest(appointments.collect { |a| a.cache_key }.join)
    
    # build cache key
    cache_key = date_key + ":" + appt_keys
  end
  
  # Create cache key for a collection of appointments over a specified daterange
  def self.slot_schedule(daterange, slots, time_of_day)
    # use daterange start and end dates
    date_key  = "#{daterange.start_at.to_s(:appt_schedule)}:#{daterange.end_at.to_s(:appt_schedule)}"
    date_key  += ":#{time_of_day}" if !time_of_day.blank?
    
    # add appointment info using an md5 hash
    slot_keys = Digest::MD5.hexdigest(slots.collect { |s| s.cache_key }.join)
    
    # build cache key
    cache_key = date_key + ":" + slot_keys
  end

end