class SitemapsController < ApplicationController
  caches_page :events

  layout nil # turn off layouts
  
  def events
    @protocol = self.request.protocol
    @host = self.request.host
    
    respond_to do |format|
      format.xml
    end
  end
  
  def tags

    respond_to do |format|
      format.xml
    end
  end

end