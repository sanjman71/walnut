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
	attr_accessible         :name, :country, :state, :city, :zip, :street_address, :lat, :lng, :source_id, :source_type
  
  acts_as_taggable_on     :locality_tags
  
  named_scope :for_state, lambda { |state| { :conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] }}
  named_scope :for_city,  lambda { |city| { :conditions => ["city_id = ?", city.is_a?(Integer) ? city : city.id] }}
  
  named_scope :places,    lambda { {:conditions => ["locatable_type = 'Place'"], :include => :locatable } } do 
                            def tag_counts
                              # delegate to locatable
                              self.collect { |o| o.locatable.tag_counts }.flatten
                            end
                          end

  named_scope :recommended,         { :conditions => ["recommendations_count > 0"] }
  named_scope :event_venues,        { :conditions => ["events_count > 0"] }

  # find location by the specified source id
  named_scope :find_by_source,      lambda { |source| { :conditions => {:source_id => source.id, :source_type => source.class.to_s} }}
  named_scope :find_by_source_id,   lambda { |source_id| { :conditions => {:source_id => source_id} }}
  
  
  define_index do
    indexes street_address, :as => :street_address
    indexes locality_tags.name, :as => :locality_tags
    indexes locatable.name, :as => :name
    indexes locatable.tags.name, :as => :place_tags
    has locatable.tags(:id), :type => :integer, :as => :tag_ids, :facet => true, :multi => true
    indexes search_rank, :as => :search_rank, :sortable => true
    # locality attributes, all faceted
    has country_id, :type => :integer, :as => :country_id, :facet => true
    has state_id, :type => :integer, :as => :state_id, :facet => true
    has city_id, :type => :integer, :as => :city_id, :facet => true
    has zip_id, :type => :integer, :as => :zip_id, :facet => true
    has location_neighborhoods.neighborhood_id, :type => :integer, :as => :neighborhood_ids, :facet => true, :multi => true
    # other attributes
    has locatable.chain_id, :type => :integer, :as => :chain_id
    has recommendations_count, :type => :integer, :as => :recommendations
    has event_venue, :type => :integer, :as => :event_venue
    # convert degrees to radians for sphinx
    has 'RADIANS(lat)', :as => :lat,  :type => :float
    has 'RADIANS(lng)', :as => :lng,  :type => :float
    # delta indexing using a delayed/background processing scheduler so its 'almost' real-time
    set_property :delta => :delayed
  end
  
  # return collection of location's country, state, city, zip, neighborhoods
  def localities
    [country, state, city, zip].compact + neighborhoods.compact
  end
  
  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng
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
  
  # after_save callback to update locality tags (e.g. country, state, city, zip) based on changes to the location object
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
