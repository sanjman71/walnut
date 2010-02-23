class CacheExpire

  # cache expiration constants

  def self.localities
    4.hours
  end
  
  def self.tags
    4.hours
  end

  def self.locations
    4.hours
  end
  
  def self.events
    4.hours
  end

  def self.weather
    2.hours
  end

  def self.footer
    3.days
  end

end