class AutocompleteController < ApplicationController
  skip_before_filter :init_current_privileges
  
  def where
    @q = params[:q].to_s.strip
    
    # populate list of cities and neighborhooods
    @where = City.find(:all, :include => :state, :conditions => ["name LIKE ?", @q+'%'], :limit => 7, :order => "locations_count DESC").collect do |city|
      "#{city.name}, #{city.state.code}"
    end
  
    # @where += Neighborhood.find(:all, :include => :city).collect do |neighborhood|
    #   "#{neighborhood.name}, #{neighborhood.city.name}, #{neighborhood.city.state.name}"
    # end
    
    # filter results by query
    # @where = @where.grep(/^#{@q}/i)
    
    respond_to do |format|
      format.html { render(:layout => false, :text => @where.join("\n")) }
      format.json { render(:json => @where.to_json) }
    end  
  end
end