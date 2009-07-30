class TaggsController < ApplicationController
  
  privilege_required 'manage site', :on => :current_user
  
  def index
    @search = params[:search].to_s
    
    case @search
    when ""
      @groups       = TagGroup.order_by_name
      @search_text  = @groups.blank? ? "No Tag Groups" : "All Tag Groups (#{@groups.size})"
    when "empty"
      @groups       = TagGroup.empty.order_by_companies_count
      @search_text  = "Empty Tag Groups (#{@groups.size})"
    else
      @groups       = TagGroup.search_name_and_tags(@search).order_by_name
      @search_text  = "#{@groups.size} Tag Groups matching '#{@search}'"
    end
    
    @title  = "Tag Groups"
  end

  def create
    @group  = TagGroup.create(params[:tag_group])
    
    if @group.valid?
      # edit new group
      redirect_to(edit_tagg_path(@group))
    else
      flash[:error] = "Tag Group #{@group.name} already exists"
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
    
    # update name
    @group.name = params[:name]
    
    # build add, remove keyword lists
    @group.add_tags(params[:add_tags])
    @group.remove_tags(params[:remove_tags])
    @group.save
    
    # apply tag changes to places
    @group.apply
    
    flash[:notice] = "Updated tag group '#{@group.name}'"
    
    redirect_to(taggs_path)
  end
  
  def show
    @tagg   = TagGroup.find(params[:id], :include => :places)
    
    # find places tagged with this group
    @places = @tagg.places.paginate(:page => params[:page], :per_page => 50)
    
    @title  = "Tag Group '#{@tagg.name}'"
  end
end