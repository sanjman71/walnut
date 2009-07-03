class Location < ActiveRecord::Base
  has_many                :locatables_locations
  has_many                :locatables, :through => :locatables_locations

  # All addresses must have a country
  validates_presence_of   :country_id

  belongs_to              :country
  belongs_to              :state
  belongs_to              :city
  belongs_to              :zip
  has_many                :location_neighborhoods
  has_many                :neighborhoods, :through => :location_neighborhoods, :after_add => :after_add_neighborhood, :before_remove => :before_remove_neighborhood
  has_many                :location_places
  has_many                :places, :through => :location_places
  has_many                :phone_numbers, :as => :callable
  has_one                 :event_venue
  has_many                :events, :after_add => :after_add_event, :after_remove => :after_remove_event
  has_many                :location_neighbors
  has_many                :neighbors, :through => :location_neighbors
  
  has_many                :location_sources
  has_many                :sources, :through => :location_sources
  
  after_save              :after_save_callback

  attr_accessor           :city_str, :zip_str, :state_str, :country_str

  # make sure only accessible attributes are written to from forms etc.
  attr_accessible         :name, :country, :country_id, :state, :state_id, :city, :city_id, :zip, :zip_id, :street_address, :lat, :lng, :source_id, :source_type, :city_str, :zip_str, :state_str, :country_str
  
  # used to generated an seo friendly url parameter
  acts_as_friendly_param  :place_name
  
  named_scope :with_state,            lambda { |state| { :conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] }}
  named_scope :with_city,             lambda { |city| { :conditions => ["city_id = ?", city.is_a?(Integer) ? city : city.id] }}
  named_scope :with_neighborhoods,    { :conditions => ["neighborhoods_count > 0"] }
  named_scope :no_neighborhoods,      { :conditions => ["neighborhoods_count = 0"] }
  named_scope :with_taggings,         { :include => :places, :conditions => ["places.taggings_count > 0"] }
  named_scope :no_taggings,           { :include => :places, :conditions => ["places.taggings_count = 0"] }
  named_scope :urban_mapped,          { :conditions => ["urban_mapping_at <> ''"] }
  named_scope :not_urban_mapped,      { :conditions => ["urban_mapping_at is NULL"] }
  named_scope :with_events,           { :conditions => ["events_count > 0"] }
  named_scope :with_neighbors,        { :include => :location_neighbors, :conditions => ["location_neighbors.location_id > 0"] }
  named_scope :with_phone_numbers,    { :conditions => ["phone_numbers_count > 0"] }
  named_scope :no_phone_numbers,      { :conditions => ["phone_numbers_count = 0"] }
  named_scope :min_phone_numbers,     lambda { |x| {:conditions => ["phone_numbers_count >= ?", x] }}
  named_scope :min_popularity,        lambda { |x| {:conditions => ["popularity >= ?", x] }}

  named_scope :recommended,           { :conditions => ["recommendations_count > 0"] }

  def before_validation
    if self.city_id.blank? && self.neighborhoods.first
      city_id_will_change!
      self.city_id = self.neighborhoods.first.city.id
    end
    if self.city_id && self.state.blank?
      state_id_will_change!
      self.state_id = self.city.state.id
    end
    if self.zip_id && self.state.blank?
      state_id_will_change!
      self.state_id = self.zip.state.id
    end
    if self.state_id && self.country.blank?
      country_id_will_change!
      self.country_id = self.state.country.id
    end
  end
  
  def city=(new_city)
    if (new_city)
      city_id_will_change!
      state_id_will_change!
      country_id_will_change!
      self.city_id = new_city.id
      self.state = new_city.state
      self.country = new_city.state.country
    else
      city_id_will_change!
      self.city_id = nil
    end
  end
  
  def zip=(new_zip)
    if (new_zip)
      zip_id_will_change!
      state_id_will_change!
      country_id_will_change!
      self.zip_id = new_zip.id
      self.state = new_zip.state
      self.country = new_zip.state.country
    else
      zip_id_will_change!
      self.zip_id = nil
    end
  end
  
  def state=(new_state)
    if (new_state)
      state_id_will_change!
      country_id_will_change!
      self.state_id = new_state.id
      self.country = new_state.country
    else
      state_id_will_change!
      self.state_id = nil
    end
  end

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

  def self.anywhere
    Location.new do |l|
      l.name = "Anywhere"
      l.send(:id=, 0)
    end
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
  
  def primary_phone_number
    return nil if phone_numbers_count == 0
    phone_numbers.first
  end
  
  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng
    false
  end
  
  def refer_to?
    self.refer_to > 0
  end
  
  def geocode_latlng(options={})
    force = options.has_key?(:force) ? options[:force] : false
    return true if self.lat and self.lng and !force
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode("#{street_address}, #{city.name} #{state.name} #{country}")
    return false unless geo.success
    self.lat, self.lng = geo.lat, geo.lng
    self.save
  end
  
  # return md5 location digest
  def to_digest
    s = "#{self.place_name}:#{self.street_address}:#{self.city ? self.city.name : ''}:#{self.state ? self.state.name : ''}:#{self.zip ? self.zip.name : ''}:#{self.country ? self.country.name : ''}"
    Digest::MD5.hexdigest(s)
  end
  
  # This function accepts an address in the temporary string fields which we'll convert to a geocoded set of references and will normalize the
  # city, state, country and zip to those that come back from the Google geocoder.
  # If the address isn't in these strings, then the database references should be assigned
  def normalize_and_geocode
    
    if (self.street_address.blank?)
      errors.add(:street_address, "You must enter a street address.")
    elsif (self.city_str.blank?)
      if (self.city.blank?)
        errors.add(:city, "You must enter a city.")
      else
        self.city_str = self.city.name
      end
    elsif (self.state_str.blank? && self.state.blank?)
      if (self.city.blank?)
        errors.add(:state, "You must enter a state.")
      else
        self.state_str = self.state.name
      end
    elsif (self.country_str.blank? && self.country.blank?)
      if (self.city.blank?)
        # Assume the country is the US if none entered
        self.country_str = "US"
      else
        self.country_str = self.country.name
      end
    end

    if errors.empty?
      # Geocode the address. We pull out unit #'s etc from the street address
      sa_components = StreetAddress.components(self.street_address)
      tmp_sa = StreetAddress.normalize("#{sa_components[:housenumber]} #{sa_components[:streetname]}")
      
      geo=GeoKit::Geocoders::MultiGeocoder.geocode("#{tmp_sa} #{self.city_str} #{self.state_str} #{self.country_str}")

      if !geo.success
        errors.add_to_base("Sorry, this address could not be located. Please re-enter it.")
      else
        if (!self.country = Country.find_by_code(geo.country_code))
          errors.add(:country_str, "Sorry, we do not support that country yet.")
        end
        if (!self.state = State.find_or_create_by_code(:code => geo.state, :name => geo.state, :country => country))
          errors.add(:state_str, "Sorry, we had a problem adding the state #{geo.state}.")
        end
        if (!self.zip = Zip.find_or_create_by_name(:name => geo.zip, :state => state))
          errors.add(:zip_str, "Sorry, we had a problem adding the zip #{geo.zip}.")
        end
        if (!self.city = City.find_or_create_by_name(:name => geo.city, :state => state))
          errors.add(:city_str, "Sorry, we had a problem adding the city #{geo.city}.")
        end
      end
    end
  end
  
  protected
  
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
        # decrement counter cache
        klass.decrement_counter(:locations_count, locality.id)
      end
      
      if new_id
        locality = klass.find_by_id(new_id.to_i)
        # increment counter cache
        klass.increment_counter(:locations_count, locality.id)
      end
    end
  end
  
  def after_add_neighborhood(hood)
    return if hood.blank?
  end
  
  def before_remove_neighborhood(hood)
    return if hood.blank?
    # decrement counter caches
    Neighborhood.decrement_counter(:locations_count, hood.id)
    Location.decrement_counter(:neighborhoods_count, self.id)
  end

  def after_add_event(event)
    return if event.blank?
    # increment events_count
    Location.increment_counter(:events_count, self.id)
    # increment popularity
    Location.increment_counter(:popularity, self.id)
    # add tags
    add_venue_tag
  end
  
  def after_remove_event(event)
    return if event.blank?
    # decrement events_count
    Location.decrement_counter(:events_count, self.id)
    # decrement popularity
    Location.decrement_counter(:popularity, self.id)
    # remve tags
    remove_venue_tag
  end

  def add_venue_tag
    return unless @place = self.place
    # add tag 'venue'
    @place.tag_list.add("venue")
    @place.save
  end
  
  def remove_venue_tag
    return unless @place = self.place
    # remove tag 'venue'
    @place.tag_list.remove("venue")
    @place.save
  end
end
