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
  end
  
end