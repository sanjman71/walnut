require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

namespace :db do  
  namespace :populate do
    
    require 'populator'
    require 'faker'
    require 'test/factories'
    
    desc "Populate addresses."
    task :addresses, :count do |t, args|
      count = args.count.to_i
      count = 20 if count == 0
      
      Address.populate count do |address|
        address.name = Faker::Name.name
      end
      
      puts "#{Time.now}: added #{count} addresses"
    end    
  end # populate
end # db