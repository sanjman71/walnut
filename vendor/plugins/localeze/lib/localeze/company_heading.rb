module Localeze
  class CompanyHeading < ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    belongs_to  :base_record, :class_name => "Localeze::BaseRecord"
    belongs_to  :category, :class_name => "Localeze::Category"
    belongs_to  :condensed_detail, :class_name => "Localeze::CondensedDetail"
    belongs_to  :normalized_detail, :class_name => "Localeze::NormalizedDetail"
  end
end
