class DebugController < ApplicationController
  
  # GET /debug/blueprint_grid
  # PUT /debug/blueprint_grid
  def toggle_blueprint_grid
    # toggle blueprint grid debug switch
    $BlueprintGrid = $BlueprintGrid ? false : true
    
    if request.referrer
      redirect_to(request.referrer) and return
    else
      redirect_to("/") and return
    end
  end
  
end