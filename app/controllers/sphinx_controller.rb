class SphinxController < ApplicationController

  privilege_required 'manage site', :on => :current_user, :unless => :auth_token?

  # GET /sphinx
  def index
    # show all sphinx indexes and their last updated_at timestamp

    config    = ThinkingSphinx::Configuration.instance
    files     = (Dir.glob(config.searchd_file_path + "/*_core.spa") + Dir.glob(config.searchd_file_path + "/*_delta.spa")).sort

    @objects  = files.inject([]) do |array, s|
      match = s.match(/\/([a-z]*)_(core).spa/) || s.match(/\/([a-z]*)_(delta).spa/)
      next if match.blank?
      
      model = match[1]  # e.g. location, appointment
      type  = match[2]  # core or delta
      mtime = File.mtime(s) # last updated_at timestamp
      array.push(:model => "#{model} #{type}".titleize, :index => "#{model}_#{type}", :updated_at => mtime)
    end
  end
  
  # GET /sphinx/reindex/:index_name - e.g. 'location_core'
  def reindex
    # queue job
    Delayed::Job.enqueue(SphinxJob.new(:index => params[:index]), 0)
    flash[:notice] = "Re-building sphinx index '#{params[:index]}'"
    redirect_to sphinx_index_path and return
  end

end