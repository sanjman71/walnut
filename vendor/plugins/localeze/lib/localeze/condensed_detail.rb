module Localeze
  class CondensedDetail <ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of :name

    has_many      :company_headings, :class_name=> "Localeze::CompanyHeading"
    has_many      :base_records, :through => :company_headings
  end
end
