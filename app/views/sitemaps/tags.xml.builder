xml.instruct! :xml, :version=>"1.0"
xml.urlset(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") {
  @popular_tags.each do |tag|
    xml.url do
      xml.loc(@protocol + @host + url_for(:controller => 'search', :action => 'index', :klass => 'search', :country => @country, :state => @state, :city => @city, :tag => tag.name.to_url_param))
    end
  end
}