class State < ActiveRecord::Base
  validates_presence_of       :name, :code, :country_id
  validates_uniqueness_of     :name
  belongs_to                  :country
  has_many                    :cities
  has_many                    :zips
  has_many                    :locations

  include NameParam
  
  # find states with locations
  named_scope :with_locations,    { :conditions => ["locations_count > 0"] }

  # find states with events, 1 means there are events, 0 means no events
  named_scope :with_events,       { :conditions => ["events > 0"] }
  
  # order states by location count
  named_scope :order_by_density,  { :order => "locations_count DESC" }
  
  def geocode_latlng(options={})
    force = options.has_key?(:force) ? options[:force] : false
    return true if self.lat and self.lng and !force
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode("#{name}")
    return false unless geo.success
    self.lat, self.lng = geo.lat, geo.lng
    self.save
  end
  
end
