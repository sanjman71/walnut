xml.instruct! :xml, :version=>"1.0"
xml.urlset(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  xml.url do
    xml.loc(@protocol + @host + "/menus")
  end
}