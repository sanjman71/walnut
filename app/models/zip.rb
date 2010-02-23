class Zip < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_format_of         :name, :with => /\d{5,5}/
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state, :counter_cache => true
  belongs_to                  :timezone
  has_many                    :locations
  has_many                    :city_zips
  has_many                    :cities, :through => :city_zips
  has_one                     :city, :through => :city_zips, :order => "cities.locations_count DESC"
  has_many                    :geo_tag_counts, :as => :geo
  has_many                    :tags, :through => :geo_tag_counts
  
  acts_as_mappable

  include GeoTagCountModule

  include NameParam

  attr_accessible             :name, :state, :state_id, :lat, :lng

  named_scope :with_locations,        { :conditions => ["locations_count > 0"] }
  named_scope :with_events,           { :conditions => ["events_count > 0"] }
  named_scope :with_tags,             { :conditions => ["tags_count > 0"] }
  named_scope :no_tags,               { :conditions => ["tags_count = 0"] }

  named_scope :no_latlng,             { :conditions => ["lat IS NULL and lng IS NULL"] }

  named_scope :exclude,               lambda { |zip| {:conditions => ["id <> ?", zip.is_a?(Integer) ? zip : zip.id] } }
  named_scope :within_state,          lambda { |state| {:conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] } }

  named_scope :min_density,           lambda { |density| { :conditions => ["locations_count >= ?", density] }}

  # order zips by location count
  named_scope :order_by_density,      {:order => "zips.locations_count DESC"}

  # order zips by name
  named_scope :order_by_name,         { :order => "name ASC" }
  named_scope :order_by_state_name,   { :order => "state_id ASC, name ASC" }

  def to_csv
    [self.name, self.state.code, self.lat, self.lng].join("|")
  end

  def to_param
    self.name
  end

  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng
    false
  end
end
