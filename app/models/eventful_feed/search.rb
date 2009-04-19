require 'eventful/api'

module EventfulFeed

  class Search
    
    @@method = "events/search"
  
    def self.session
      @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
    end
  
    # search events using the eventful api, with options:
    #  - :keywords
    #  - :category => category id or name
    #  - :location => e.g. "Chicago"
    #  - :date => "All", "Future", "Past", "Today", "Last Week", "This Week", "Next week"
    #          => months by name, e.g. 'October'
    #          => exact ranges take the form 'YYYYMMDDHH-YYYYMMDDHH', e.g. '2008042500-2008042723'
    #  - :sort_order => 'popularity', 'date', 'title', 'relevance', or 'venue_name', default is 'popularity'
    def self.call(options={})
      search_options = {:date => 'Future'}
      session.call(@@method, search_options.update(options))
    end
  
  end
  
end