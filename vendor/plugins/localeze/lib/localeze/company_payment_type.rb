module Localeze
  class CompanyPaymentType <ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of     :base_record_id, :payment_type
    validates_uniqueness_of   :payment_type, :scope => :base_record_id
    belongs_to                :base_record, :class_name => "Localeze::BaseRecord"
  end
end
