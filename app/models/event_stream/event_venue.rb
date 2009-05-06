require 'eventful/api'

class EventVenue < ActiveRecord::Base
  validates_presence_of     :name, :source_id, :source_type
  validates_uniqueness_of   :name
  
  belongs_to                :location
  has_many                  :events#, :after_add => :after_add_event, :after_remove => :after_remove_event
  
  named_scope :city,            lambda { |s| { :conditions => {:city => s}} }
  
  # find event venues that have been mapped/unmapped to locations
  named_scope :mapped,          { :conditions => ["location_id > 0"] }
  named_scope :unmapped,        { :conditions => ["location_id is NULL"] }

  
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

  # convert object to a string of attributes separated by '|'
  def to_pipe
    [self.name, self.search_name, self.address_name].join("|")
  end
  
  def self.import(city, options)
    page_number   = options[:page] ? options[:page].to_i : 1
    page_size     = options[:per_page] ? options[:per_page].to_i : 50
    
    @results      = EventVenue.search(:sort_order => 'popularity', :location => city.name, :page_number => page_number, :page_size => page_size)
    @venues       = @results['venues'] ? @results['venues']['venue'] : []
    
    @total        = @results['total_items']
    @count        = @results['page_items']   # the number of events on this page
    @first_item   = @results['first_item']   # the first item number on this page, e.g. 11
    @last_item    = @results['last_item']    # the last item number on this page, e.g. 20
    
    start_count   = EventVenue.count
    
    @venues.each do |venue|
      EventVenue.create(:name => venue['venue_name'], :city => venue['city_name'], :address => venue['address'], 
                        :source_type => EventSource::Eventful, :source_id => venue['id'])
    end
    
    imported = EventVenue.count - start_count
  end
  
end
