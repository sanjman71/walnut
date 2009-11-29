xml.instruct! :xml, :version=>"1.0" 
xml.urlset(
    :xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9",
    :"xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
    :"xsi:schemaLocation"=>"http://www.sitemaps.org/schemas/sitemap/0.9
	                                     http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
) {


  @cities_list = sitemap_events_list
  @cities_list.each do |name, path|
    xml.url do
      xml.loc(@protocol + @host + path)
      xml.changefreq("daily")
    end
  end

}