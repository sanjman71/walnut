require 'eventful/api'

module EventStream

  class Init
    
    def self.session
      @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
    end

    def self.categories
      method        = "categories/list"
      results       = session.call(method)
      categories    = results['category']
      start_count   = EventCategory.count
      
      popular_list  = ["Concerts", "Festivals", "Nightlife", "Organizations", "Sports"]
      
      categories.each do |category|
        # format category name
        category_name = category['name'].gsub(" | ", ', ')
        source_id     = category['id']
        source_type   = EventSource::Eventful
        
        # create category
        options   = {:name => category_name, :source_id => source_id, :source_type => source_type}
        category  = EventCategory.find_by_name(category_name) || EventCategory.create(options)
        
        puts "xxx #{category.errors.full_messages}" if !category.valid?
        
        # mark popular categories
        if popular_list.any? { |s| category_name.match(/#{s}/) }
          category.update_attribute(:popularity, 1)
        else
          category.update_attribute(:popularity, 0)
        end
      end
      
      imported = EventCategory.count - start_count
    end
    
    def self.venues(options)
      page_number   = options[:page] ? options[:page].to_i : 1
      page_size     = options[:limit] ? options[:limit].to_i : 50
      
      @results      = EventVenue.search(:sort_order => 'popularity', :location => 'Chicago', :page_number => page_number, :page_size => page_size)
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
  
end