class Address < ActiveRecord::Base
  validates_presence_of   :name
  
  has_many                :address_areas
  has_many                :areas, :through => :address_areas, :after_add => :add_area_tag, :before_remove => :remove_area_tag
  
  acts_as_taggable_on     :tags, :area_tags
  
  define_index do
    indexes :name, :sortable => true
    indexes area_tags.name, :as => :area_tags
  end

  protected
  
  def add_area_tag(area)
    return false if area.blank? or area.extent.blank?
    area_tag_list.add(area.extent.name)
    area_tag_list.sort!
    save
  end
  
  def remove_area_tag(area)
    return false if area.blank? or area.extent.blank?
    area_tag_list.remove(area.extent.name)
    save
  end
  
end
