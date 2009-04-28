module Localeze
  
  class Chain < ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of   :name
    has_many                :base_records, :class_name => "Localeze::BaseRecord"
  end
  
end