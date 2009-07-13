class State < ActiveRecord::Base
  validates_presence_of       :name, :code, :country_id
  validates_uniqueness_of     :name
  belongs_to                  :country
  has_many                    :cities
  has_many                    :zips
  has_many                    :locations

  include NameParam
  
  attr_accessible             :name, :code, :country, :country_id, :lat, :lng

  # find states with locations
  named_scope :with_locations,    { :conditions => ["locations_count > 0"] }

  # find states with events, 1 means there are events, 0 means no events
  named_scope :with_events,       { :conditions => ["events > 0"] }

  # find all states in a particular country, defaults to country #1 (presumably the US)
  named_scope :in_country,        lambda {|*args| {:conditions => ["country_id = ?", args.first || 1] } }
  
  # order alphabetically by code
  named_scope :order_by_code,     { :order => "code" }
  
  # order alphabetically by name
  named_scope :order_by_name,     { :order => "name" }

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
