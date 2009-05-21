class Location < ActiveRecord::Base
  validates_presence_of   :name
  belongs_to              :country
  belongs_to              :state
  belongs_to              :city
  belongs_to              :zip
  has_many                :location_neighborhoods
  has_many                :neighborhoods, :through => :location_neighborhoods, :after_add => :after_add_neighborhood, :before_remove => :before_remove_neighborhood
  has_many                :location_places
  has_many                :places, :through => :location_places
  has_one                 :event_venue
  has_many                :events, :after_add => :after_add_event, :after_remove => :after_remove_event

  has_many                :location_neighbors
  
  before_save             :before_save_callback
  after_save              :after_save_callback

  # make sure only accessible attributes are written to from forms etc.
	attr_accessible         :name, :country, :country_id, :state, :state_id, :city, :city_id, :zip, :zip_id, :street_address, :lat, :lng, :source_id, :source_type
  
  # used to generated an seo friendly url parameter
  acts_as_friendly_param  :place_name
  
  # acts_as_taggable_on     :locality_tags
  
  named_scope :for_state, lambda { |state| { :conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] }}
  named_scope :for_city,  lambda { |city| { :conditions => ["city_id = ?", city.is_a?(Integer) ? city : city.id] }}
  
  named_scope :with_neighborhoods,    { :conditions => ["neighborhoods_count > 0"] }
  named_scope :without_neighborhoods, { :conditions => ["neighborhoods_count = 0"] }
  named_scope :urban_mapped,          { :conditions => ["urban_mapping_at <> ''"] }
  named_scope :not_urban_mapped,      { :conditions => ["urban_mapping_at is NULL"] }
  named_scope :with_events,           { :conditions => ["events_count > 0"] }
  named_scope :recommended,           { :conditions => ["recommendations_count > 0"] }

  named_scope :with_neighbors,        { :include => :location_neighbors, :conditions => ["location_neighbors.location_id > 0"] }
  
  # find location by the specified source id
  named_scope :find_by_source,      lambda { |source| { :conditions => {:source_id => source.id, :source_type => source.class.to_s} }}
  named_scope :find_by_source_id,   lambda { |source_id| { :conditions => {:source_id => source_id} }}
  
  
  define_index do
    indexes places.name, :as => :name
    indexes street_address, :as => :address
    indexes places.tags.name, :as => :tags
    has places.tags(:id), :as => :tag_ids, :facet => true
    # locality attributes, all faceted
    has country_id, :type => :integer, :as => :country_id, :facet => true
    has state_id, :type => :integer, :as => :state_id, :facet => true
    has city_id, :type => :integer, :as => :city_id, :facet => true
    has zip_id, :type => :integer, :as => :zip_id, :facet => true
    has neighborhoods(:id), :as => :neighborhood_ids, :facet => true
    # other attributes
    has popularity, :type => :integer, :as => :popularity
    has places.chain_id, :type => :integer, :as => :chain_ids
    has recommendations_count, :type => :integer, :as => :recommendations
    has events_count, :type => :integer, :as => :events, :facet => true
    # convert degrees to radians for sphinx
    has 'RADIANS(locations.lat)', :as => :lat,  :type => :float
    has 'RADIANS(locations.lng)', :as => :lng,  :type => :float
    # delta indexing using a delayed/background processing scheduler so its 'almost' real-time
    set_property :delta => :delayed
    # only index valid locations
    where "status = 0"
  end
  
  # return location's first place
  def place
    self.places.first
  end

  def place_name
    self.place ? self.place.name : self.name
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
  
  # return md5 location digest
  def to_digest
    s = "#{self.place_name}:#{self.street_address}:#{self.city ? self.city.name : ''}:#{self.state ? self.state.name : ''}:#{self.zip ? self.zip.name : ''}:#{self.country ? self.country.name : ''}"
    Digest::MD5.hexdigest(s)
  end

  protected
  
  # before_save callback to:
  #  - update digest
  def before_save_callback
    changed_set = ["country_id", "state_id", "city_id", "zip_id", "name"]

    self.changes.keys.each do |change|
      # filter out unless its a locality or name
      next unless changed_set.include?(change.to_s)
      # update digest
      self.digest = self.to_digest
    end
  end

  # after_save callback to:
  #  - increment/decrement locality counter caches
  #  x (deprecated) update locality tags (e.g. country, state, city, zip) based on changes to the location object
  def after_save_callback
    changed_set = ["country_id", "state_id", "city_id", "zip_id"]
    
    self.changes.keys.each do |change|
      # filter out unless its a locality
      next unless changed_set.include?(change.to_s)
      
      begin
        # get class object
        klass_name  = change.split("_").first.titleize
        klass       = Module.const_get(klass_name)
      rescue
        next
      end
      
      old_id, new_id = self.changes[change]
      
      if old_id
        locality = klass.find_by_id(old_id.to_i)
        # remove locality tag
        # locality_tag_list.remove(locality.name)
        # decrement counter cache
        klass.decrement_counter(:locations_count, locality.id)
      end
      
      if new_id
        locality = klass.find_by_id(new_id.to_i)
        # add locality tag
        # locality_tag_list.add(locality.name)
        # increment counter cache
        klass.increment_counter(:locations_count, locality.id)
      end
    end
  end
  
  def after_add_neighborhood(hood)
    return if hood.blank?
    # add locality tag
    # locality_tag_list.add(hood.name)
    # save
  end
  
  def before_remove_neighborhood(hood)
    return if hood.blank?
    # decrement counter caches
    Neighborhood.decrement_counter(:locations_count, hood.id)
    Location.decrement_counter(:neighborhoods_count, self.id)
    # remove locality tag
    # locality_tag_list.remove(hood.name)
    # save
  end
  
  def after_add_event(event)
    return if event.blank?
    # increment events_count
    Location.increment_counter(:events_count, self.id)
  end
  
  def after_remove_event(event)
    return if event.blank?
    # decrement events_count
    Location.decrement_counter(:events_count, self.id)
  end
  
end
