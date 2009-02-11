class Location < ActiveRecord::Base
  validates_presence_of   :name
  belongs_to              :country
  belongs_to              :state
  belongs_to              :city
  belongs_to              :zip
  
  has_many                :locality_locations
  has_many                :localities, :through => :locality_locations, :after_add => :after_add_locality, :before_remove => :before_remove_locality
  
  belongs_to              :locatable, :polymorphic => true, :counter_cache => :locations_count
  
  after_save              :update_localities
  
  # make sure only accessible attributes are written to from forms etc.
	attr_accessible         :name, :country, :state, :city, :zip, :street_address
  
  acts_as_taggable_on     :locality_tags, :place_tags
  
  define_index do
    indexes locatable.name
    indexes street_address
    indexes locality_tags.name, :as => :locality_tags
    indexes place_tags.name, :as => :place_tags
  end
    
  protected
  
  # after_save callback to update areas based on changes detected using dirty objects
  def update_localities
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
        object.localities.each do |locality|
          begin
            # remove location/locality mapping
            LocalityLocation.destroy(LocalityLocation.find_by_locality_id_and_location_id(locality.id, self.id))
          rescue; end
          # remove area tag
          locality_tag_list.remove(locality.extent.name)
        end
      end
      
      if new_id
        # add new areas
        object = klass.find_by_id(new_id.to_i)
        object.localities.each do |locality|
          # add address/area mapping
          LocalityLocation.create(:location_id => self.id, :locality_id => locality.id)
          # add area tag
          locality_tag_list.add(locality.extent.name)
        end
      end
    end
  end
  
  # after_add locality callback to add locality tags
  def after_add_locality(locality)
    return false if locality.blank? or locality.extent.blank?
    locality_tag_list.add(locality.extent.name)
    save
  end
  
  # before_remove locality callback to remove locality tags
  def before_remove_locality(locality)
    return false if locality.blank? or locality.extent.blank?
    locality_tag_list.remove(locality.extent.name)
    save
  end
  
end
