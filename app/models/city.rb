class City < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state, :counter_cache => true
  has_many                    :city_zips
  has_many                    :zips, :through => :city_zips
  has_many                    :neighborhoods
  has_many                    :locations
  
  acts_as_mappable
  
  include NameParam
  
  named_scope :exclude,       lambda { |city| {:conditions => ["id <> ?", city.is_a?(Integer) ? city : city.id] } }
  named_scope :within_state,  lambda { |state| {:conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] } }
  
  # find cities with locations
  named_scope :with_locations,    { :conditions => ["locations_count > 0"] }
  
  # order cities by location count
  named_scope :order_by_density,  { :order => "locations_count DESC" }
  
  # the special anywhere object
  def self.anywhere(state=nil)
    City.new do |o|
      o.name      = "Anywhere"
      o.state_id  = state.id if state
      o.send(:id=, 0)
    end
  end
  
  def anywhere?
    self.id == 0
  end
  
  def geocode_latlng(options={})
    force = options.has_key?(:force) ? options[:force] : false
    return true if self.lat and self.lng and !force
    # multi-geocoder geocode does not throw an exception on failure
    geo = Geokit::Geocoders::MultiGeocoder.geocode("#{name}, #{state.name}")
    return false unless geo.success
    self.lat, self.lng = geo.lat, geo.lng
    self.save
  end
  
end
