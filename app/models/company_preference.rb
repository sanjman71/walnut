class CompanyPreference
  
  #
  # default company preference values
  #

  def self.default_time_horizon
    28.days
  end

  def self.default_start_wday
    0
  end

  def self.default_appt_start_minutes
    [0,30]
  end

end