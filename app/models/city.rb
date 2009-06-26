class City < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state, :counter_cache => true
  has_many                    :neighborhoods
  has_many                    :locations
  
  acts_as_mappable
  
  include NameParam
  
  named_scope :exclude,       lambda { |city| {:conditions => ["id <> ?", city.is_a?(Integer) ? city : city.id] } }
  named_scope :within_state,  lambda { |state| {:conditions => ["state_id = ?", state.is_a?(Integer) ? state : state.id] } }
  
  # find cities with locations
  named_scope :with_locations,        { :conditions => ["locations_count > 0"] }
  
  named_scope :min_density,           lambda { |density| { :conditions => ["locations_count >= ?", density] }}

  # order cities by location count
  named_scope :order_by_density,      { :order => "locations_count DESC" }
  
  # order cities by name
  named_scope :order_by_name,         { :order => "name ASC" }
  named_scope :order_by_state_name,   { :order => "state_id ASC, name ASC" }
  
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
  
  def to_param
    self.name.parameterize.to_s
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

  def has_locations?
    self.locations_count > 0
  end
  
  # convert city to a string of attributes separated by '|'
  def to_csv
    [self.name, self.state.code, self.lat, self.lng].join("|")
  end
  
  # import cities
  def self.import(options={})
    imported  = 0
    file      = options[:file] ? options[:file] : "#{RAILS_ROOT}/data/cities.txt"
    
    FasterCSV.foreach(file, :col_sep => '|') do |row|
      city_name, state_code, lat, lng = row

      # validate state
      state = State.find_by_code(state_code)
      next if state.blank?

      # skip if city exists
      next if state.cities.find_by_name(city_name)

      # create city
      city = state.cities.create(:name => city_name, :lat => lat, :lng => lng)
      imported += 1
    end
    
    imported
  end
  
end
