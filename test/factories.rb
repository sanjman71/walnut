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

Factory.sequence :source_id do |n|
  n
end
