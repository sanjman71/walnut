class LocationNeighbor < ActiveRecord::Base
  belongs_to              :location
  belongs_to              :neighbor, :class_name => "Location", :foreign_key => "neighbor_id"
  validates_uniqueness_of :neighbor_id, :scope => :location_id
  
  named_scope :for_location,        lambda { |location| {:conditions => ["location_id = ?", location.is_a?(Integer) ? location : location.id], 
                                                         :include => [:neighbor, {:neighbor => [:city, :places]}] }}
                                                        
  # named_scope :venue,               { :joins => :neighbor, :conditions => ['locations.events_counts > 0'] }
  named_scope :order_by_distance,   { :order => "distance asc"}
  
  def self.default_limit
    7
  end
  
  def self.default_radius_miles
    10.0
  end

  def self.default_radius_meters
    Math.miles_to_meters(self.default_radius_miles)
  end
  
  def self.find_neighbors(location, options={})
    return [] if location.blank?
    limit = options[:limit] ? options[:limit].to_i : self.default_limit
    LocationNeighborCollection.new(LocationNeighbor.for_location(location).order_by_distance.all(:limit => limit))
  end
  
  def self.partition_neighbors(location, options={})
    return [] if location.blank?

    # parse options
    limit       = options[:limit] ? options[:limit].to_i : self.default_limit
    
    # find all neighbors
    collection  = find_neighbors(location, :limit => limit*2)
    
    # partition by regular and event venue locations
    regulars    = LocationNeighborCollection.new
    venues      = LocationNeighborCollection.new
    
    collection.each do |object|
      object.neighbor.events_count == 0 ? regulars.push(object) : venues.push(object)
    end
    
    [regulars, venues]
  end
  
  # set regular and event venue neighbors for the specified location
  def self.set_neighbors(location, localities, options={})
    raise ArgumentError, "location is blank" if location.blank?
    raise ArgumentError, "location is not mappable" if !location.mappable?
    
    # parse options
    limit       = options[:limit] ? options[:limit].to_i : self.default_limit
    
    attributes  = ::Search.attributes(Array(localities))
    hash        = ::Search.query("events:0")
    attributes  = attributes.update(hash[:attributes])

    if options[:geodist]
      attributes["@geodist"] = options[:geodist]
    end

    origin      = [Math.degrees_to_radians(location.lat).to_f, Math.degrees_to_radians(location.lng).to_f]
    locations   = Location.search(:geo => origin, :with => attributes, :without_ids => location.id, :order => "@geodist asc",  :limit => limit)

    # set regular location neighbors
    locations.each_with_geodist do |neighbor, distance|
      # convert meters to miles
      miles = Math.meters_to_miles(distance.to_f)
      # add (unique) neighbor
      LocationNeighbor.create(:location => location, :neighbor => neighbor, :distance => miles)
    end

    hash        = ::Search.query("events:1")
    attributes  = attributes.update(hash[:attributes])

    if options[:geodist]
      attributes["@geodist"] = options[:geodist]
    end

    locations   = Location.search(:geo => origin, :with => attributes, :without_ids => location.id, :order => "@geodist asc",  :limit => limit)

    # set event venue location neighbords
    locations.each_with_geodist do |neighbor, distance|
      # convert meters to miles
      miles = Math.meters_to_miles(distance.to_f)
      # add (unique) neighbor
      LocationNeighbor.create(:location => location, :neighbor => neighbor, :distance => miles)
    end
  end
end