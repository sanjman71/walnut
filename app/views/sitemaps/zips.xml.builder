xml.instruct! :xml, :version=>"1.0"
xml.urlset(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  
  @zips.each do |zip|
    xml.url do
      xml.loc(@protocol + @host + zip_path(@country, @state, zip))
    end
  end
  
}