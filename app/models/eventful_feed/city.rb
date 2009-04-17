module EventfulFeed

  class City < ActiveRecord::Base
    set_table_name "eventful_cities"
    validates_presence_of     :name
  end
  
end