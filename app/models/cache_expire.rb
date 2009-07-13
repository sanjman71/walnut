class CacheExpire
  
  # cache expiry constants
  
  def self.localities
    5.minutes
  end
  
  def self.tags
    5.minutes
  end

  def self.locations
    5.minutes
  end
  
  def self.events
    5.minutes
  end
  
  def self.facets
    5.minutes
  end
end