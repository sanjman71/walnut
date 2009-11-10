namespace :chains do
  
  desc "Initialize chain display names"
  task :init_display_names do
    changed = 0
    
    Chain.all(:order => 'name').each do |chain|
      # skip chains with valid display names
      next unless chain.read_attribute(:display_name).blank?
      
      # build histogram of all chain company names
      company_names = chain.companies.inject(Hash.new(0)) do |hash, company|
        hash[company.name] = hash[company.name] + 1
        hash
      end

      # use the most comman place name as the display name
      sorted  = company_names.sort { |a, b| -a[1] <=> -b[1] }
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

  desc "Initialize chain states hash"
  task :init_chain_states do
    Chain.order_by_company.each do |chain|
      # find all chain states
      states = State.all(:joins => {:locations => :companies}, :conditions => {:companies => {:chain_id => chain.id}}).uniq.sort_by{ |o| o.id }
      puts "*** #{chain.display_name}: found #{states.size} states"

      hash = states.inject(Hash[]) do |hash, state|
        # find chain cities
        cities    = City.all(:joins => {:locations => :companies}, :conditions => {:companies => {:chain_id => chain.id}, :locations => {:state_id => state.id}}).uniq
        city_ids  = cities.collect(&:id)

        # add hash entry mapping state id to city ids
        hash[state.id] = city_ids
        hash
      end
      chain.states = hash
      chain.save
    end

    puts "#{Time.now}: completed"
  end

end