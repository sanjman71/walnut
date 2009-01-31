require 'factory_girl'

Factory.define :state do |o|
  o.name        "Illinois"
  o.ab          "IL"
  o.country     "US"
end

Factory.define :city do |o|
  o.name        "Chicago"
  o.state       { |o| Factory(:state) }
end