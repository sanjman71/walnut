module Localeze
  class NormalizedDetail <ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of :name

    has_many      :company_headings, :class_name=> "Localeze::CompanyHeading"
    has_many      :base_records, :through => :company_headings
    
    named_scope   :search_name,           lambda { |s| {:conditions => ["name REGEXP '%s'", s] }}
  end
end