require 'factory_girl'

Factory.define :us, :class => :Country do |o|
  o.name        "United States"
  o.code        "US"
end

Factory.define :state do |o|
  o.name        "Illinois"
  o.code        "IL"
end

Factory.define :city do |o|
  o.name        "Chicago"
  o.state       { |o| Factory(:state) }
end

Factory.define :zip do |o|
  o.name        "60654"
  o.state       { |o| Factory(:state) }
end

Factory.define :neighborhood do |o|
  o.name        "River North"
  o.city        { |o| Factory(:city) }
end