namespace :chains do
  
  desc "Initialize chain display names"
  task :init_display_names do
    changed = 0
    
    Chain.all(:order => 'name').each do |chain|
      # skip chains with valid display names
      next unless chain.read_attribute(:display_name).blank?
      
      # build histogram of all chain place names
      place_names = chain.places.inject(Hash.new(0)) do |hash, place|
        hash[place.name] = hash[place.name] + 1
        hash
      end

      # use the most comman place name as the display name
      sorted  = place_names.sort { |a, b| -a[1] <=> -b[1] }
      name    = sorted.first[0]
      
      if chain.display_name != name
        puts "*** chain: #{chain.name}: setting display name to: #{name}"
        chain.display_name = name
        chain.save
        changed += 1
      end
    end
    
    puts "#{Time.now}: completed, changed #{changed} display names"
  end
end