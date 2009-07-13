class CompanyService < ActiveRecord::Base
  belongs_to                :company  # the counter cache is managed using callbacks in the company model
  belongs_to                :service
end
