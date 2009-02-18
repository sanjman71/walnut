module Localeze
  
  class BaseRecord <ActiveResource::Base
    self.site = "http://localhost:3002/"
    
    def street_address
      [housenumber, predirectional, streetname, streettype, postdirectional, apttype, aptnumber].delete_if { |s| s.blank? }.join(" ")
    end
    
    # returns true iff the base record has a latitude and longitude 
    def mappable?
      return true if self.latitude and self.longitude
      false
    end
  end
  
end