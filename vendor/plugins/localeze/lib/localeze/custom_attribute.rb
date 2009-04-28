module Localeze
  class CustomAttribute < ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of     :base_record_id, :name
    validates_uniqueness_of   :name, :scope => :base_record_id
    belongs_to                :base_record, :class_name => "Localeze::BaseRecord"
  end
end