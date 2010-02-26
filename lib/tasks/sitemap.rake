namespace :sitemap do
  
  # example sitemap range queries using curl
  # curl http://www.walnutplaces.com/sitemap.locations.il.chicago.[1-25].xml
  # curl http://www.walnutplaces.com/sitemap.locations.ny.new-york.[1-25].xml >/dev/null 2>&1
  # curl http://www.walnutplaces.com/sitemap.locations.cities.small.[1-25].xml >/dev/null 2>&1
  # curl http://www.walnutplaces.com/sitemap.locations.cities.tiny.[1-25].xml >/dev/null 2>&1
  desc "generate city sitemaps"
  task :city do
    @country  = Country.us
    @state    = State.find_by_code(ENV['STATE'])
    @city     = @state.cities.find_by_name(ENV["CITY"].titleize)
    @start    = ENV["START"].to_i
    @end      = ENV["END"].to_i
    @root     = "http://www.walnutplaces.com/sitemap.locations.#{@state.code.to_url_param}.#{@city.name.to_url_param}."
    
    # build url using curl range syntax
    @url      = @root + "[#{@start}-#{@end}].xml"
    puts @url

    # don't execute command, just print it out
    # exec "curl #{@url} >/dev/null 2>&1"

    # puts "#{Time.now}: completed"
  end

end