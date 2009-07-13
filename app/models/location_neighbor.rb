class LocationNeighbor < ActiveRecord::Base
  belongs_to              :location
  belongs_to              :neighbor, :class_name => "Location", :foreign_key => "neighbor_id"
  validates_uniqueness_of :neighbor_id, :scope => :location_id
  
  named_scope :with_location,       lambda { |location| {:conditions => ["location_id = ?", location.is_a?(Integer) ? location : location.id], 
                                                         :include => [:neighbor, {:neighbor => [:city, :places]}] }}
     
  # find all 'distinct' locations having neighbors with the specified city or state
  named_scope :with_city,           lambda { |city| { :conditions => ["locations.city_id = ?", city.id], :joins => :location, :group => "location_id" }}
  named_scope :with_state,          lambda { |state| { :conditions => ["locations.state_id = ?", state.id], :joins => :location, :group => "location_id" }}
                                                     
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
  
  def self.get_neighbors(location, options={})
    return [] if location.blank?
    limit = options[:limit] ? options[:limit].to_i : self.default_limit
    LocationNeighborCollection.new(LocationNeighbor.with_location(location).order_by_distance.all(:limit => limit))
  end
  
  def self.partition_neighbors(location, options={})
    return [] if location.blank?

    # parse options
    limit       = options[:limit] ? options[:limit].to_i : self.default_limit
    
    # get all neighbors
    collection  = get_neighbors(location, :limit => limit*2)
    
    # partition by regular and event venue locations
    regulars    = LocationNeighborCollection.new
    venues      = LocationNeighborCollection.new
    
    collection.each do |object|
      object.neighbor.events_count == 0 ? regulars.push(object) : venues.push(object)
    end
    
    [regulars, venues]
  end
  
  # set regular and event venue neighbors for the specified location
  def self.set_neighbors(location, options={})
    raise ArgumentError, "location is blank" if location.blank?
    raise ArgumentError, "location is not mappable" if !location.mappable?
    
    # parse options
    limit       = options[:limit] ? options[:limit].to_i : self.default_limit
    args_attr   = options[:attributes] ? options[:attributes] : Hash.new
    delete      = options[:delete] == true

    # get old neighbors, track new neighbors
    new_set     = []
    old_set     = get_neighbors(location, :limit => 2**30).collect{ |o| o.neighbor } if delete

    hash        = ::Search.query("events:0")
    attributes  = args_attr.dup.update(hash[:attributes])

    if options[:geodist]
      attributes["@geodist"] = options[:geodist]
    end

    origin      = [Math.degrees_to_radians(location.lat).to_f, Math.degrees_to_radians(location.lng).to_f]
    locations   = Location.search(:geo => origin, :with => attributes, :without_ids => location.id, :order => "@geodist asc",  :limit => limit,
                                  :retry_stale => true)

    # set regular location neighbors
    locations.each_with_geodist do |neighbor, distance|
      # convert meters to miles
      miles = Math.meters_to_miles(distance.to_f)
      # add (unique) neighbor
      LocationNeighbor.create(:location => location, :neighbor => neighbor, :distance => miles)
      # track new set
      new_set.push(neighbor)
    end

    hash        = ::Search.query("events:1")
    attributes  = args_attr.dup.update(hash[:attributes])

    if options[:geodist]
      attributes["@geodist"] = options[:geodist]
    end

    origin      = [Math.degrees_to_radians(location.lat).to_f, Math.degrees_to_radians(location.lng).to_f]
    locations   = Location.search(:geo => origin, :with => attributes, :without_ids => location.id, :order => "@geodist asc", :limit => limit,
                                  :retry_stale => true)

    # set event venue location neighbors
    locations.each_with_geodist do |neighbor, distance|
      # convert meters to miles
      miles = Math.meters_to_miles(distance.to_f)
      # add (unique) neighbor
      LocationNeighbor.create(:location => location, :neighbor => neighbor, :distance => miles)
      # track new set
      new_set.push(neighbor)
    end

    if delete
      # delete all old neighbors not in the new neighbor set
      del_set = old_set - new_set
      del_set.each do |neighbor|
        loc_neighbor = LocationNeighbor.find_by_location_id_and_neighbor_id(location.id, neighbor.id)
        loc_neighbor.destroy
      end
    end

    new_set
  end
end