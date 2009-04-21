require 'eventful/api'

module EventfulFeed

  class Venue < ActiveRecord::Base
    set_table_name "eventful_venues"
    validates_uniqueness_of :name, :scope => :city
    
    belongs_to  :location, :counter_cache => :event_venue
    
    # find event venues that have been mapped/unmapped to locations
    named_scope :mapped,      { :conditions => ["location_id > 0"] }
    named_scope :unmapped,    { :conditions => ["location_id is NULL"] }
    
    @@method = "venues/search"
  
    def self.session
      @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
    end
  
    # search venues using the eventful api, with options:
    #  - :keywords => string
    #  - :location => e.g. "Chicago"
    #  - :sort_order => 'popularity', 'relevance', or 'venue'; default is 'relevance'
    def self.call(options={})
      search_options = {:sort_order => 'relevance'}
      session.call(@@method, search_options.update(options))
    end
      
  end
  
end