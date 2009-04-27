require 'eventful/api'

class EventVenue < ActiveRecord::Base
  validates_presence_of     :name, :source_id, :source_type
  validates_uniqueness_of   :name
  
  belongs_to                :location
  has_many                  :events, :after_add => :set_events_count, :after_remove => :set_events_count
  
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
  
  protected
  
  def set_events_count(event)
    # set location events counter
    return if location.blank?
    location.update_attribute(:events_count, events.size)
  end
  
end
