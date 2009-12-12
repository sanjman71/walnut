xml.instruct! :xml, :version=>"1.0"
xml.sitemapindex(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  @range.each do |i|
    xml.sitemap do
      xml.loc(@protocol + @host + @root + "#{i}.xml")
    end
  end
}