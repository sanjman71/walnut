xml.instruct! :xml, :version=>"1.0"
xml.urlset(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  @locations.each do |location|
    xml.url do
      xml.loc(@protocol + @host + "/locations/" + location.to_param)
    end
  end
}