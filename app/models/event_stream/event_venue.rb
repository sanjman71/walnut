require 'eventful/api'

class EventVenue < ActiveRecord::Base
  validates_presence_of     :name, :source_id, :source_type
  validates_uniqueness_of   :name
  
  belongs_to                :location
  has_many                  :events
  
  after_save                :init_location_source
  
  # find event venues in a specific city
  named_scope :city,              lambda { |s| { :conditions => {:city => s.is_a?(City) ? s.name : s}} }
  
  # find event venues that have been mapped/unmapped to locations
  named_scope :mapped,            { :conditions => ["location_id > 0"] }
  named_scope :unmapped,          { :conditions => ["location_id is NULL"] }
  
  # find event venues mapped to a localeze record location
  named_scope :localeze,          { :conditions => {:location_source_type => "Localeze::BaseRecord"}}
  
  named_scope :order_popularity,  { :order => "popularity DESC" }
  named_scope :order_city,        { :order => "city ASC" }

  @@search_method       = "venues/search"
  @@get_method          = "venues/get"
  @@event_get_method    = "events/get"
  
  def self.session
    @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
  end
  
  # call class method
  def get(options={})
    EventVenue.get(self.source_id, options)
  end

  # convert object to a pipe separated list of attributes
  def to_pipe
    [self.city, self.name, self.location_source_type, self.location_source_id].join("|")
  end

  # returns true if the event venue is mapped to a location
  def mapped?
    !self.location_id.blank?
  end
  
  # try to map the venue to location
  def map_to_location(options={})
    log   = options[:log] ? true : false
    
    city  = City.find_by_name(self.city)
    
    if city.blank?
      if log
        puts "#{Time.now}: xxx could not find venue city #{self.city}"
      end
      
      return 0
    end
    
    # create search object to build query
    search      = ::Search.parse([], self.name)
    name        = search.query
    
    # break street address into components and normalize
    components  = StreetAddress.components(self.address)
    address     = StreetAddress.normalize("#{components[:housenumber]} #{components[:streetname]}")
    
    # check if there a source id and type
    if self.location_source_id and self.location_source_type
      # find the location
      matches = Location.find(:all, :conditions => {:source_id => self.location_source_id, :source_type => self.location_source_type})
    else
      # search with constraints
      matches = Location.search(name, :conditions => {:city_id => city.id, :street_address => address})
    end
    
    if matches.blank?
      # no matches
      if log
        puts "#{Time.now}: xxx no search matches for venue '#{name}', address #{address}"
      end
      
      return 0
    elsif matches.size > 1

      if search.blank?
        # too many matches
        if log
          puts "#{Time.now}: xxx found #{matches.size} matches for venue '#{name}', address #{address}"
        end
        
        return 0
      end

      # try again with a more restrictive search
      if log
        puts "#{Time.now}: found #{matches.size} matches for venue #{name}, address #{address} ... trying again"
      end
      
      name    = search.query(:operator => :and)
      matches = Location.search(name, :conditions => {:city_id => city.id, :street_address => address})
      
      if matches.size != 1
        # this search faield as well, its time to give up and just add the venue as a place
        if log
          puts "#{Time.now}: xxx retry, found #{matches.size} matches for venue #{name}, address #{address}"
        end
        
        return 0
      end
    end
        
    # found a matching location, mark location as an event venue
    self.location = matches.first
    self.save

    if log
      puts "#{Time.now}: *** marked location: #{location.place.name}:#{location.street_address} as event venue:#{self.name}"
    end
    
    return 1
  end
  
  # add the event venue as a place
  def add_place(options={})
    log     = options[:log] ? true : false
    
    # create location parameters
    state   = State.find_by_name(self.state)
    city    = state.cities.find_by_name(self.city) if state
    
    if state.blank? or city.blank?
      if log
        puts "#{Time.now}: venue has an invalid city or state"
      end
      
      return 0
    end

    # create location
    address = StreetAddress.normalize(self.address)
    zip     = state.zips.find_by_name(self.zip)
    options = {:name => "Venue", :street_address => address, :city => city, :state => state, :zip => zip, :country => Country.default}

    options.merge!(:source_id => self.source_id, :source_type => self.source_type)
    options.merge!(:lat => self.lat, :lng => self.lng) if self.lat and self.lng
    location  = Location.create(options)
  
    # create place
    place = Place.create(:name => self.name)
    place.locations.push(location)
    place.reload
    
    # map location to event venue
    self.location = location
    self.save
    
    if log
      puts "#{Time.now}: *** added place: #{place.name}:#{location.name}:#{location.id} as an event venue"
    end
    
    return 1
  end
  
  # import venue events; return the events imported
  def import_events(options={})
    limit     = options[:limit] ? options[:limit].to_i : 2**30
    imported  = []
    
    begin
      results  = venue.get
      events   = results['events']['event']
    rescue Exception => e
      puts "xxx exception: #{e.message}"
      return imported
    end
    
    events.each do |eventful_event|
      event = import_event(eventful_event)
      imported.push(event) unless event.blank?
    end
    
    imported
  end

  def import_event(event_hash, options={})
    log   = options[:log] ? true : false
    
    # check if event exits
    event = Event.find_by_source_id(event_hash['id'])
    
    return event if event
    
    options  = {:name => event_hash['title'], :url => event_hash['url'], :source_type => self.source_type, :source_id => event_hash['id']}
    options[:start_at]  = event_hash['start_time'] if event_hash['start_time']
    options[:end_at]    = event_hash['stop_time'] if event_hash['stop_time']
    
    # create event
    event = Event.create(options)

    if log
      puts "#{Time.now}: *** created event: #{event.name} @ #{self.name}"
    end
    
    # add event to event venue and location
    self.events.push(event)
    self.location.events.push(event)

    event
  end
  
  # search venues using the eventful api, with options:
  #  - :keywords => string
  #  - :location => e.g. "Chicago"
  #  - :sort_order => 'popularity', 'relevance', or 'venue'; default is 'relevance'
  def self.search(options={})
    search_options = {:sort_order => 'relevance'}
    session.call(@@search_method, search_options.update(options))
  end

  # get event venue info, e.g. events, ...
  def self.get(id, options={})
    get_options = {:id => id}
    EventVenue.session.call(@@get_method, get_options.update(options))
  end
  
  # get event info
  def self.event_get(id, options={})
    get_options = {:id => id}
    EventVenue.session.call(@@event_get_method, get_options.update(options))
  end
  
  # import venues sorted by popularity
  def self.import(city, options)
    page_number   = options[:page] ? options[:page].to_i : 1
    page_size     = options[:per_page] ? options[:per_page].to_i : 50
    log           = options[:log] ? true : false
    
    results       = EventVenue.search(:sort_order => 'popularity', :location => city.name, :page_number => page_number, :page_size => page_size)
    venues        = results['venues'] ? results['venues']['venue'] : []
    
    @total        = @results['total_items']
    @count        = @results['page_items']   # the number of events on this page
    @first_item   = @results['first_item']   # the first item number on this page, e.g. 11
    @last_item    = @results['last_item']    # the last item number on this page, e.g. 20
    
    start_count   = EventVenue.count
    
    venues.each_with_index do |venue, index|
      import_venue(venue, :log => log)
    end
    
    imported = EventVenue.count - start_count
  end

  def self.import_venue(venue_hash, options={})
    log     = options[:log] ? true : false
    options = {:name => venue_hash['name'], :city => venue_hash['city'], :address => venue_hash['address'], :zip => venue_hash["postal_code"],
               :source_type => EventSource::Eventful, :source_id => venue_hash['id']}
    options[:lat] = venue_hash['latitude'] if venue_hash['latitude']
    options[:lng] = venue_hash['longitude'] if venue_hash['longitude']
    options[:area_type] = venue_hash['venue_type'] if venue_hash['venue_type']
    
    # map region name to a state
    state   = State.find_by_name(venue_hash['region'])
    options[:state] = state.name if state
    
    # create event venue
    object  = EventVenue.create(options)

    if object and log
      puts "#{Time.now}: *** added venue #{object.name}:#{object.city}:#{object.state}:#{object.zip}:#{object.area_type}"
    end
    
    object
  end
  
  def self.import_metadata(city, options={})
    file  = "#{RAILS_ROOT}/data/event_venues.txt"
    count = 0
    
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => '|') do |row|
      city_name, name, type, id = row

      # apply city filter
      next if city_name != city
      
      # find event venue
      event_venue = EventVenue.find_by_name(name)
      next if event_venue.blank?
      next if event_venue.location_source_type and event_venue.location_source_id
      
      # apply metadata
      options = {:location_source_type => type, :location_source_id => id}
      event_venue.update_attributes(options)
      
      count += 1
    end
    
    count
  end
  
  def self.tag_event(event, options={})
    log = options[:log] ? true : false

    begin
      results         = EventVenue.event_get(event.source_id)
      categories_hash = results['categories']['category']
    rescue Exception => e
      puts "xxx exception: #{e.message}"
      next
    end

    # map eventful category id to an event category object
    categories = categories_hash.map do |category_hash|
      EventCategory.find_by_source_id(category_hash['id'])
    end.compact
    
    # associate event categories with events
    categories.compact.each do |category|
      if log
        puts "#{Time.now}: *** tagging event: #{event.name} with category: #{category.name}"
      end
      event.event_categories.push(category)
    end
  end
  
  protected
  
  # initialize location_source fields if the event venue has been mapped to a location
  def init_location_source
    return if location.blank?
    return if !self.location_source_id.blank? or !self.location_source_type.blank?
    self.location_source_id   = location.source_id
    self.location_source_type = location.source_type
    self.save
  end
end
