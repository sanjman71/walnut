class EventCategory < ActiveRecord::Base
  validates_presence_of     :name, :source_type, :source_id
  validates_uniqueness_of   :name
  
  has_many                  :event_category_mappings, :dependent => :destroy
  has_many                  :events, :through => :event_category_mappings
  
  named_scope :popular,         { :conditions => ["popularity > 0"] }
  named_scope :order_by_name,   { :order => "name ASC" }
  
  def to_param
    self.source_id.dasherize
  end
  
  # convert object to a string of attributes separated by '|'
  def to_pipe
    [self.name, self.tags].join("|")
  end
  
  def self.session
    @@session ||= Eventful::API.new(EVENTFUL_API_KEY)
  end
  
  @@list_method   = "categories/list"
  
  def self.import
    results       = session.call(@@list_method)
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
  
end
  