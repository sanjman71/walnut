require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :populate do
    
    require 'populator'
    require 'faker'
    require 'test/factories'

    desc "Populate places."
    task :places, :count do |t, args|
      count = args.count.to_i
      count = 20 if count == 0

      Place.populate count do |place|
        place.name = Faker::Name.name
      end
    end
    
    desc "Populate addresses."
    task :addresses, :count do |t, args|
      count = args.count.to_i
      count = 20 if count == 0
      
      Address.populate count do |address|
        address.name = 'Home'
      end
      
      puts "#{Time.now}: added #{count} addresses"
    end    
  end # populate
end # db