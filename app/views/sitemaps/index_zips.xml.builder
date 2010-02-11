xml.instruct! :xml, :version=>"1.0"
xml.sitemapindex(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  @states.each do |state|
    xml.sitemap do
      xml.loc(@protocol + @host + "/sitemap.zips.%s.xml" % state.code.downcase)
    end
  end
}