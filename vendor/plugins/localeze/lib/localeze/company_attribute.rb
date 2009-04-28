module Localeze
  class CompanyAttribute < ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of     :base_record_id, :name, :group_name
    validates_uniqueness_of   :name, :scope => :base_record_id
    belongs_to                :base_record, :class_name => "Localeze::BaseRecord"
    belongs_to                :category, :class_name => "Localeze::Category"

    def tags
      [name.downcase]
    end
    
  end
end