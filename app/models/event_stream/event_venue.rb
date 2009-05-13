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
  
  named_scope :order_popularity,  { :order => "popularity DESC" }
  

  @@search_method   = "venues/search"
  @@get_method      = "venues/get"
  
  def self.session
    @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
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
  def get(options={})
    get_options = {:id => self.source_id}
    EventVenue.session.call(@@get_method, get_options.update(options))
  end

  # convert object to a comma separated list of attributes
  def to_csv
    [self.city, self.name, self.location_source_type, self.location_source_id].join(",")
  end

  # returns true if the event venue is mapped to a location
  def mapped?
    !self.location_id.blank?
  end
  
  # import venue events, and return the events imported
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

  def import_event(eventful_event, options={})
    log   = options[:log] ? true : false
    
    # check if event exits
    event = Event.find_by_source_id(eventful_event['id'])
    
    return event if event
    
    options  = {:name => eventful_event['title'], :url => eventful_event['url'], :source_type => self.source_type, :source_id => eventful_event['id']}
    options[:start_at]  = eventful_event['start_time'] if eventful_event['start_time']
    options[:end_at]    = eventful_event['stop_time'] if eventful_event['stop_time']
    
    # create event
    event = Event.create(options)

    if log
      puts "*** created event: #{event.name}"
    end
    
    # add event to event venue and location
    self.events.push(event)
    self.location.events.push(event)

    event
  end
  
  # tag all venue's events with categories, which has the affect of applying category tags
  def categorize_events(options={})
    self.events.each do |event|
      # skip if event already has categories
      next if !event.event_categories.blank?
      
      begin
        @results    = event.get
        @categories = @results['categories']['category']
      rescue Exception => e
        puts "xxx exception: #{e.message}"
        next
      end

      # map eventful category id to an event category object
      @categories = @categories.map do |category|
        # puts "*** category: #{category}"
        EventCategory.find_by_source_id(category['id'])
      end
      
      # associate event categories with events
      @categories.compact.each do |category|
        puts "*** category: #{category.name}, event: #{event.name}"
        event.event_categories.push(category)
      end
    end
  end
  
  # import venues sorted by popularity
  def self.import(city, options)
    page_number   = options[:page] ? options[:page].to_i : 1
    page_size     = options[:per_page] ? options[:per_page].to_i : 50
    log           = options[:log] ? true : false
    
    @results      = EventVenue.search(:sort_order => 'popularity', :location => city.name, :page_number => page_number, :page_size => page_size)
    @venues       = @results['venues'] ? @results['venues']['venue'] : []
    
    @total        = @results['total_items']
    @count        = @results['page_items']   # the number of events on this page
    @first_item   = @results['first_item']   # the first item number on this page, e.g. 11
    @last_item    = @results['last_item']    # the last item number on this page, e.g. 20
    
    start_count   = EventVenue.count
    
    @venues.each_with_index do |venue, index|
      @popularity = @total - (@first_item + index)
      object = EventVenue.create(:name => venue['venue_name'], :city => venue['city_name'], :address => venue['address'], :zip => venue["postal_code"],
                                 :popularity => @popularity, :source_type => EventSource::Eventful, :source_id => venue['id'])

      if object and log
        puts "*** added event venue #{object.name}:#{object.city}:#{object.popularity}"
      end
    end
    
    imported = EventVenue.count - start_count
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
