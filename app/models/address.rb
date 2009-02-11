class Address < ActiveRecord::Base
  validates_presence_of   :name
  belongs_to              :country
  belongs_to              :state
  belongs_to              :city
  belongs_to              :zip
  
  has_many                :address_areas
  has_many                :areas, :through => :address_areas, :after_add => :after_add_area, :before_remove => :before_remove_area
  
  belongs_to              :addressable, :polymorphic => true, :counter_cache => :addresses_count
  
  after_save              :update_areas
  
  # make sure only accessible attributes are written to from forms etc.
	attr_accessible         :name, :country, :state, :city, :zip, :street_address
  
  acts_as_taggable_on     :area_tags, :place_tags
  
  define_index do
    indexes addressable.name
    indexes street_address
    indexes area_tags.name, :as => :area_tags
    indexes place_tags.name, :as => :place_tags
  end
    
  protected
  
  # after_save callback to update areas based on changes detected using dirty objects
  def update_areas
    self.changes.keys.each do |change|
      # filter out unless its an area
      next unless ["country_id", "state_id", "city_id", "zip_id"].include?(change.to_s)
      begin
        # get class object
        klass_name  = change.split("_").first.titleize
        klass       = Module.const_get(klass_name)
      rescue
        next
      end
      
      old_id, new_id = self.changes[change]
      
      if old_id
        # remove old area
        object = klass.find_by_id(old_id.to_i)
        object.areas.each do |area|
          begin
            # remove address/area mapping
            AddressArea.destroy(AddressArea.find_by_address_id_and_area_id(self.id, area.id))
          rescue; end
          # remove area tag
          area_tag_list.remove(area.extent.name)
        end
      end
      
      if new_id
        # add new areas
        object = klass.find_by_id(new_id.to_i)
        object.areas.each do |area|
          # add address/area mapping
          AddressArea.create(:address_id => self.id, :area_id => area.id)
          # add area tag
          area_tag_list.add(area.extent.name)
        end
      end
    end
  end
  
  # after_add area callback to add area tags
  def after_add_area(area)
    return false if area.blank? or area.extent.blank?
    area_tag_list.add(area.extent.name)
    save
  end
  
  # before_remove area callback to remove area tags
  def before_remove_area(area)
    return false if area.blank? or area.extent.blank?
    area_tag_list.remove(area.extent.name)
    save
  end
  
end
