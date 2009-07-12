class BotStatsController < ApplicationController

  privilege_required 'manage site', :on => :current_user

  def googlebot
    # show crawler stats for the last 90 days
    @stats  = BotStat.googlebot.order_by_most_recent.all(:limit => 90)
    
    @title  = "Google Bot Crawler Stats"
    @h1     = "Google Bot Crawler Stats"
  end
  
  def googlemedia
    
  end
  
end