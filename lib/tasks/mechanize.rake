require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

# include named routes
include ActionController::UrlWriter

namespace :mechanize do
  
  case RAILS_ENV
  when 'development'
    @@host = 'www.walnutplaces.dev:3000'
  when 'production'
    @@host = 'www.walnutplaces.com'
  end

  desc "Add location neighbors"
  task :neighbors do
    isleep  = ENV["SLEEP"] ? ENV["SLEEP"].to_i : 0
    limit   = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**32-1

    agent   = WWW::Mechanize.new
    count   = 0

    puts "#{Time.now}: finding all locations with no neighbors"

    # find locations with no neighbors
    Location.find_each(:batch_size => 1000) do |location|
      next if location.location_neighbors.count > 0
      url = location_url(location, :host => @@host)
      url += "?neighbors=1"
      # puts "*** url: #{url.inspect}"
      agent.get(url)
      count += 1
      break if count >= limit
      if (count % 1000)== 0
        puts "#{Time.now}: added neighbors to #{count} locations"
      end
      sleep(isleep) if isleep > 0
    end
    
    puts "#{Time.now}: added neighbors to #{count} locations"
  end # task
  
end # mechanize
