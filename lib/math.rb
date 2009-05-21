module Math
  def self.degrees_to_radians(degree) 
    degree * Math::PI / 180 
  end
  
  def self.meters_to_miles(meter)
    meter.to_f * 0.000621371192
  end
  
  def self.miles_to_meters(miles)
    miles.to_f * 1609.344
  end
end