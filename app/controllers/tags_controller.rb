class TagsController < ApplicationController
  
  privilege_required 'read tags', :only => [:index], :on => :current_user
  
  def index
    @search   = params[:search].to_s
    order     = "taggings_count DESC"
    per_page  = 30
    
    case @search
    when ""
      @tags         = Tag.all(:order => order).paginate(:page => params[:page], :per_page => per_page)
    else
      @tags         = Tag.all(:conditions => ["name REGEXP '%s'", @search], :order => order)
      @search_text  = "#{@tags.size} Tags matching '#{@search}'"
    end
    
    @title  = "Tags"
  end
  
end