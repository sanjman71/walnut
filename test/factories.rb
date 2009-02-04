require 'factory_girl'

Factory.define :us, :class => :Country do |o|
  o.name        "United States"
  o.ab          "US"
end

Factory.define :state do |o|
  o.name        "Illinois"
  o.ab          "IL"
end

Factory.define :city do |o|
  o.name        "Chicago"
  o.state       { |o| Factory(:state) }
end