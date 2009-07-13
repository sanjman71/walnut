class Zip < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_format_of         :name, :with => /\d{5,5}/
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state, :counter_cache => true
  has_many                    :locations
  
  acts_as_mappable

  include NameParam

  attr_accessible             :name, :state, :state_id, :lat, :lng

  # find zips with locations
  named_scope :with_locations,        { :conditions => ["locations_count > 0"] }

  named_scope :no_lat_lng,            { :conditions => ["lat IS NULL and lng IS NULL"] }

  named_scope :exclude,               lambda { |zip| {:conditions => ["id <> ?", zip.is_a?(Integer) ? zip : zip.id] } }
  named_scope :within_state,          lambda { |state| {:conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] } }

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
