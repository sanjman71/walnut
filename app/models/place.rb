class Place < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name

  # Delete read tag methods to address model
  # delegate  :place_tags,          :to => 'addresses.first'
  # delegate  :place_tag_list,      :to => 'addresses.first'
  
  # acts_as_taggable_on       :tags
  
  # define_index do
  #   indexes addresses.area_tags.name, :as => :area_tags
  #   indexes name, :sortable => true
  #   indexes tags.name, :as => :tags
  # end
  
end