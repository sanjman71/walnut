module Localeze
  class Category < ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of :name
    has_many              :company_headings, :class_name => "Localeze::CompanyHeading"
  
    def tags
      if tag_list.blank?
        # increment reference counter
        Category.increment_counter(:reference_count, id)
        # use the category name
        [name.downcase]
      else
        # reset reference counter
        update_attribute(:reference_count, 0)
        tag_list.split(",").map(&:strip).sort
      end
    end
  
  end
end