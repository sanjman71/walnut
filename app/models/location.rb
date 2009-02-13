class Location < ActiveRecord::Base
  validates_presence_of   :name
  belongs_to              :country
  belongs_to              :state
  belongs_to              :city
  belongs_to              :zip
  has_many                :location_neighborhoods
  has_many                :neighborhoods, :through => :location_neighborhoods, :after_add => :after_add_neighborhood, :before_remove => :before_remove_neighborhood
  belongs_to              :locatable, :polymorphic => true, :counter_cache => :locations_count
  
  after_save              :update_locality_tags
  
  # make sure only accessible attributes are written to from forms etc.
	attr_accessible         :name, :country, :state, :city, :zip, :street_address
  
  acts_as_taggable_on     :locality_tags, :place_tags
  
  define_index do
    indexes locatable.name
    indexes street_address
    indexes locality_tags.name, :as => :locality_tags
    indexes place_tags.name, :as => :place_tags
  end
  
  # return collection of location's country, state, city, zip, neighborhoods
  def localities
    [country, state, city, zip].compact + neighborhoods.compact
  end
  
  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng?
    false
  end
  
  def geocode_latlng(options={})
    force = options.has_key?(:force) ? options[:force] : false
    return true if self.lat and self.lng and !force
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode("#{street_address}, #{city.name }#{state.name}")
    return false unless geo.success
    self.lat, self.lng = geo.lat, geo.lng
    self.save
  end
  
  protected
  
  # after_save callback to update locality tags (e.g. country, state, city, zip, neighborhood) based on changes to the location object
  def update_locality_tags
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
        # remove locality tag
        locality = klass.find_by_id(old_id.to_i)
        locality_tag_list.remove(locality.name)
        # decrement counter cache
        klass.decrement_counter(:locations_count, locality.id)
      end
      
      if new_id
        # add locality tag
        locality = klass.find_by_id(new_id.to_i)
        locality_tag_list.add(locality.name)
        # increment counter cache
        klass.increment_counter(:locations_count, locality.id)
      end
    end
  end
  
  def after_add_neighborhood(hood)
    return if hood.blank?
    # add locality tag
    locality_tag_list.add(hood.name)
    save
  end
  
  def before_remove_neighborhood(hood)
    return if hood.blank?
    # remove locality tag
    locality_tag_list.remove(hood.name)
    save
  end
end
