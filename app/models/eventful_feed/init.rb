require 'eventful/api'

module EventfulFeed

  class Init
    
    def self.session
      @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
    end

    def self.categories
      method        = "categories/list"
      results       = session.call(method)
      categories    = results['category']
      start_count   = Category.count
      
      popular_list  = ["Concerts", "Festivals", "Nightlife", "Organizations", "Sports"]
      
      categories.each do |category|
        # format category name
        category_name = category['name'].gsub(" | ", ', ')
        category_id   = category['id']
        
        # create category
        category = Category.find_by_name(category_name) || Category.create(:name => category_name, :eventful_id => category_id)
        
        # mark popular categories
        if popular_list.any? { |s| category_name.match(/#{s}/) }
          category.update_attribute(:popularity, 1)
        else
          category.update_attribute(:popularity, 0)
        end
      end
      
      imported = Category.count - start_count
    end
    
    def self.venues
      page_size   = 50
      
      @results    = Venue.call(:sort_order => 'popularity', :location => 'Chicago', :page_size => page_size)
      @venues     = @results['venues'] ? @results['venues']['venue'] : []
      
      @total      = @results['total_items']
      @count      = @results['page_items']   # the number of events on this page
      @first_item = @results['first_item']   # the first item number on this page, e.g. 11
      @last_item  = @results['last_item']    # the last item number on this page, e.g. 20
      
      @venues.each do |venue|
        Venue.create(:name => venue['venue_name'], :city => venue['city_name'], :address => venue['address'])
      end
      
      @venues.size
    end
    
  end
  
end