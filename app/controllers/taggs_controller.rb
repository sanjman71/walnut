class TaggsController < ApplicationController
  layout "home"
  
  def index
    @groups = TagGroup.all
    
    @title  = "Tag Groups"
  end

  def create
    @group  = TagGroup.create(params[:tag_group])
    
    if @group.valid?
      # edit new group
      redirect_to(edit_tagg_path(@group))
    else
      # back to index on an error
      redirect_to(taggs_path)
    end
  end
  
  def edit
    @group  = TagGroup.find(params[:id])

    @title  = "Edit Tag Group"
  end
  
  def update
    @group  = TagGroup.find(params[:id])
    
    # build add, remove keyword lists
    @group.add_tags(params[:add_tags])
    @group.remove_tags(params[:remove_tags])
    @group.save
    
    # apply tag changes to places
    @group.apply
    
    redirect_to(taggs_path)
  end
  
end