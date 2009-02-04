class Address < ActiveRecord::Base
  validates_presence_of   :name
  
  has_many                :address_areas
  has_many                :areas, :through => :address_areas, :after_add => :add_area_tag, :before_remove => :remove_area_tag
  
  has_many_polymorphs     :addressables, :from => [:places], :through => :address_addressables
  
  acts_as_taggable_on     :area_tags, :place_tags
  
  define_index do
    indexes area_tags.name, :as => :area_tags
    indexes places.name
    indexes place_tags.name, :as => :place_tags
  end

  protected
  
  def add_area_tag(area)
    return false if area.blank? or area.extent.blank?
    area_tag_list.add(area.extent.name)
    save
  end
  
  def remove_area_tag(area)
    return false if area.blank? or area.extent.blank?
    area_tag_list.remove(area.extent.name)
    save
  end
  
end
