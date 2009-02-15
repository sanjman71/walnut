module Math
  def self.degrees_to_radians(degree) 
    degree * Math::PI / 180 
  end
  
  def self.meters_to_miles(meter)
    meter.to_f * 0.000621371192
  end
end