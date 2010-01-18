xml.instruct! :xml, :version=>"1.0"
xml.urlset(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  xml.url do
    xml.loc(@protocol + @host + chain_country_path(@country, @chain))
  end
  
  @states.each do |state|
    xml.url do
      xml.loc(@protocol + @host + chain_state_path(@country, state, @chain))
    end
  end
  
  @cities_hash.keys.each do |state|
    cities = @cities_hash[state]
    cities.each do |city|
      xml.url do
        xml.loc(@protocol + @host + chain_city_path(@country, state, city, @chain))
      end
    end
  end
}