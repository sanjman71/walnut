class EventsController < ApplicationController

  privilege_required 'manage site', :on => :current_user

  def new
    @repeat_options = ["Does Not Repeat", "Every Weekday (Monday - Friday)", "Daily", "Weekly"]
  end
end