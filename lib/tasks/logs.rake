namespace :logs do
  
  desc "Parse access.log"
  task :parse_access_log do
    name  = "#{RAILS_ROOT}/log/access.log"
    
    puts "#{Time.now}: parsing file #{name}"
    
    tracking_google_bot     = ActiveSupport::OrderedHash.new(0)
    tracking_google_media   = ActiveSupport::OrderedHash.new(0)
    matches                 = 0
    
    File.open(name).each do |line|
      next unless line.match(/google/i)
      # puts line

      matches += 1
      
      # parse timestamp - [01/Jul/2009:02:52:21 +0000], and convert to local time
      match     = line.match(/\[(\d{2,2})\/(\w{3,3})\/(\d{4,4}):(\d{2,2}):(\d{2,2}):(\d{2,2})/)
      time      = Time.utc(match[3].to_i, match[2], match[1].to_i, match[4].to_i, match[5].to_i, match[6].to_i)
      key       = time.to_date.to_datetime
      
      # puts "time: #{time.to_s}"

      if line.match(/googlebot/i)
        # track it
        tracking_google_bot[key] = tracking_google_bot[key] + 1
      elsif line.match(/media/i)
        # track it
        tracking_google_media[key] = tracking_google_media[key] + 1
      end
    end

    puts "#{Time.now}: *** google bot"
    tracking_google_bot.each_pair do |k, v|
      puts "#{Time.now}: day: #{k}, #{v}"
      BotStat.create_or_update("googlebot", k, v)
    end

    puts "#{Time.now}: *** google media"
    tracking_google_media.each_pair do |k, v|
      puts "#{Time.now}: day: #{k}, #{v}"
      BotStat.create_or_update("googlemedia", k, v)
    end
    
    puts "#{Time.now}: completed, found #{matches} matches"
  end
  
end