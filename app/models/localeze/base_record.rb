module Localeze
  
  class BaseRecord <ActiveResource::Base
    self.site = "http://localhost:3002/"
    
    def street_address
      [housenumber, predirectional, streetname, streettype, postdirectional, apttype, aptnumber].reject(&:blank?).join(" ")
    end
    
    def phone_number
      return nil if areacode.blank? or exchange.blank? or phonenumber.blank?
      [areacode, exchange, phonenumber].join
    end
    
    # returns true iff the base record has a latitude and longitude 
    def mappable?
      return true if self.latitude and self.longitude
      false
    end
  end
  
end