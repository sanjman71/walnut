xml.instruct! :xml, :version=>"1.0"
xml.sitemapindex(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  @chains.each do |chain|
    xml.sitemap do
      xml.loc(@protocol + @host + "/sitemap.chains.%s.xml" % chain.id)
    end
  end
}