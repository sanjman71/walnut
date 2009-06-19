module UrbanMapping
  require 'curl'
  require 'json'
  
  class ExceededRateLimitError < StandardError
  end
  
  # ActiveResource uses a structured rest interface.  The urban mapping api is restful, but not very structured.
  # Here's an example call to retrieve neighborhoods by lat/lng:
  # http://api0.urbanmapping.com/neighborhoods/rest/getNeighborhoodsByLatLng?lat=40.756945&lng=-73.978243&format=json&apikey=xxyyzz
  class Neighborhood
    @@site        = "http://api0.urbanmapping.com/neighborhoods/rest"
    @@apikey      = "mhe5u25k856cgwy75wkxeyjr" # new key
    
    def self.find_all(location, options={})
      raise ArgumentError, "location is blank" if location.blank?
      raise ArgumentError, "location is not mappable" if !location.mappable?
      self.find_by_latlng(location.lat, location.lng, options)
    end
    
    # find neighborhoods using the specified latitude and longitude coordinates
    def self.find_by_latlng(lat, lng, options={})
      begin
        url         = @@site + ("/getNeighborhoodsByLatLng?lat=%f&lng=%f&format=json&apikey=%s" % [lat, lng, @@apikey])
        response    = Curl::Easy.perform(url)
        urban_hoods = JSON.parse(response.body_str)
      rescue Exception => e
        # check for if we went over our request limit
        puts "#{Time.now}: xxx #{e.message}"
        if e.message.match(/403 Developer Over Rate/)
          raise ExceededRateLimitError
        else
          # re-raise
          raise e
        end
      end

      # map/create neighborhoods
      neighborhoods = urban_hoods.collect do |hood|
        state = State.find_by_code(hood["state"])
        city  = state.cities.find_by_name(hood["city"]) if state
        
        if city.blank?
          puts "#{Time.now}: xxx invalid city, state: #{hood["city"]}:#{hood["state"]}"
          nil
        else
          # find/create neighborhood
          neighborhood  = city.neighborhoods.find_by_name(hood["name"]) || ::Neighborhood.create(:name => hood["name"], :city_id => city.id)
        end
      end
      
      neighborhoods.compact
    end
    
  end
  
end