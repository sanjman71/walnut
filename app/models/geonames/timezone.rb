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
        puts "#{Time.now}: xxx #{e.message}"
        raise e
      end
      
      puts "body: #{body}"
      puts "timezone: #{body['timezoneId']}"
    end

  end # Timezone
end # Geonames
