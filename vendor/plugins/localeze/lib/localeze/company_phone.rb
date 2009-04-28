module Localeze
  class CompanyPhone <ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of     :base_record_id, :areacode, :exchange, :phonenumber
    validates_uniqueness_of   :areacode, :exchange, :phonenumber, :scope => :base_record_id
    belongs_to                :base_record, :class_name => "Localeze::BaseRecord"
  end
end
