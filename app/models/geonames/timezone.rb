module Geonames
  class Timezone
    @@site    = "http://ws.geonames.org"
    @@method  = "#{@@site}/timezoneJSON"
    
    def self.get(lat, lng)
      begin
        url       = @@method + ("?lat=%f&lng=%f" % [lat, lng])
        response  = Curl::Easy.perform(url)
        body      = JSON.parse(response.body_str)
      rescue Exception => e
        puts "#{Time.now}: xxx exception: #{e.message}"
        raise e
      end
      
      # sample response:
      # gmtOffset-5dstOffset-4time2009-07-18 15:42lng-75.659774rawOffset-5countryNameUnited StatescountryCodeUSlat39.633141timezoneIdAmerica/New_York
      
      # map timezonid to a timezone object
      ::Timezone.find_by_name(body['timezoneId'])
    end

  end # Timezone
end # Geonames
