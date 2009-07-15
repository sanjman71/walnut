require 'factory_girl'

Factory.define :us, :class => :Country do |o|
  o.name        "United States"
  o.code        "US"
end

Factory.define :canada, :class => :Country do |o|
  o.name        "Canada"
  o.code        "CA"
end

Factory.define :country do |o|
  o.name        "United States"
  o.code        "US"
end

Factory.define :il, :class => :State do |o|
  o.name        "Illinois"
  o.code        "IL"
end

Factory.define :ontario, :class => :State do |o|
  o.name        "Ontario"
  o.code        "ON"
end

Factory.define :state do |o|
  o.name        "Illinois"
  o.code        "IL"
end

Factory.define :chicago, :class => :City do |o|
  o.name        "Chicago"
end

Factory.define :toronto, :class => :City do |o|
  o.name        "Toronto"
end

Factory.define :city do |o|
  o.name        "Chicago"
end

Factory.define :zip do |o|
  o.name        "60654"
  o.state       { |o| Factory(:state) }
end

Factory.define :neighborhood do |o|
  o.name        "River North"
  o.city        { |o| Factory(:city) }
end

Factory.define :user do |u|
  u.name                  { |s| Factory.next :user_name }
  u.email                 { |s| Factory.next :user_email }
  u.password              "secret"
  u.password_confirmation "secret"
  u.phone                 "9999999999"
end

Factory.define :location do |o|
  o.country   { |o| Factory(:country) }
  o.state     { |o| Factory(:state) }
  o.city      { |o| Factory(:city) }
  o.zip       { |o| Factory(:zip) }
end

Factory.define :company do |o|
  o.name        { |s| Factory.next :company_name }
  o.time_zone   "UTC"
end

Factory.define :monthly_plan, :class => Plan do |o|
  o.name                          "Monthly"
  o.cost                          1000  # cents
  o.start_billing_in_time_amount  1
  o.start_billing_in_time_unit    "months"
  o.between_billing_time_amount   1
  o.between_billing_time_unit     "months"
  o.enabled                       true
end

Factory.define :free_plan, :class => Plan do |o|
  o.name                          "Free"
  o.cost                          0  # cents
  o.enabled                       true
  o.max_providers                 1
  o.max_locations                 1
end

Factory.define :subscription do |o|
  o.plan        { |o| Factory(:monthly_plan, :name => "Monthly Subscription")}
  o.user        { |o| Factory(:user) }
end

Factory.define :work_service, :class => Service do |s|
  s.name                    "Work"
  s.mark_as                 "work"
  s.duration                30
  s.allow_custom_duration   false
end

Factory.define :free_service, :class => Service do |s|
  s.name                    "Available"
  s.mark_as                 "free"
  s.price                   0.00
  # no duration required for free service
end

Factory.define :event_venue do |o|
  o.name                  "Event Venue"
  o.source_type           EventSource::Eventful
  o.source_id             { |s| Factory.next :source_id }
end

Factory.define :event_category do |o|
  o.name                  "Event Category"
  o.source_type           EventSource::Eventful
  o.source_id             { |s| Factory.next :source_id }
end

Factory.sequence :user_name do |n|
  "User #{n}"
end

Factory.sequence :user_email do |n|
  "user#{n}@walnut.com"
end

Factory.sequence :company_name do |n|
  "Company #{n}"
end

Factory.sequence :source_id do |n|
  n
end
