require 'eventful/api'

module EventfulFeed

  class Init
    
    def self.session
      @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
    end

    def self.categories
      method      = "categories/list"
      results     = session.call(method)
      categories  = results['category']
      start_count = Category.count
      
      categories.each do |category|
        # create category, silently fails if category already exists
        Category.create(:name => category['name'], :eventful_id => category['id'])
      end
      
      imported = Category.count - start_count
    end
  end
  
end