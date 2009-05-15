require 'test/test_helper'
require 'test/factories'

class PlacesControllerTest < ActionController::TestCase
  
  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
  end
  
  context "search city" do
    context "with no locations" do
      setup do
        # ThinkingSphinx::Collection takes 4 arguments: page, per_page, entries, total_entries
        Location.stubs(:search).returns(ThinkingSphinx::Collection.new(1, 1, 0, 0))
        get :index, :country => 'us', :state => 'il', :city => 'chicago', :what => 'food'
      end
    
      should_respond_with :success
      should_render_template 'places/index.html.haml'
      should_assign_to(:country) { @us }
      should_assign_to(:state) { @il }
      should_assign_to(:city) { @chicago }
      should_assign_to :what, :search, :title
      should_assign_to(:query) { "food" }
      should_assign_to(:title) { "Food Places near Chicago, Illinois" }
    end
  end
end
