namespace :specials do
  
  desc "Add specials from smalltabs.com"
  task :import_from_smalltabs do
    id      = ENV["ID"] ? ENV["ID"].to_i : 1
    agent   = WWW::Mechanize.new

    Array(id).each do |i|
      url     = "http://www.smalltabs.com/details.php?id=%s" % i

      # get and parse url
      agent.get(url)
  
      # parse and map to a location
      location = parse_geo(agent)

      if location
        # parse specials for the location
        parse_specials(agent, location)
      end
    end
  end
  
  # name, e.g. Kerryman
  # name_and_address, e.g. Kerryman 500 N Clark St Chicaogo, IL 60654, 555-999-9999
  def parse_geo(agent)
    # get location name and address
    name_and_address  = agent.page.at("div.threecolumns p").text()  # e.g. Kerryman 500 N Clark St Chicaogo, IL 60654, 555-999-9999
    name              = agent.page.at("div.threecolumns p strong").text() # e.g. Kerryman
    phone             = PhoneNumber.format(agent.page.at("div.threecolumns p").text().split.last)

    puts "*** name and address: #{name_and_address}"
    
    # address is name_and_address - name
    address = name_and_address.slice(name.length(), name_and_address.length()).strip
    
    # city and state are fixed for now
    city    = 'chicago'
    state   = 'il'

    # 
    # strip city, state, zip phone from address;
    match   = address.match(/([\w\d\s]+) Chicago/)
    
    if match.blank?
      puts "[error] could not find street from #{address}"
      return nil
    end

    street = match[1]
    hash   = StreetAddress.components(street)

    # build object hash using name, street, city, state
    object    = Hash["name" => name, "address" => "#{hash[:housenumber]} #{hash[:streetname]}", "city" => city, "state" => state, "phone" => phone]

    puts "*** object: #{object.inspect}"

    locations = Special.match(object)
    
    # puts "*** locations: #{locations.inspect}"
    
    if locations.empty?
      puts "[error] no location found"
      return nil
    elsif locations.size > 1
      puts "[error] #{locations.size} found"
      return nil
    end
    
    locations.first
  end

  def parse_specials(agent, location)
    agent.page.search("table.chart tr").each_with_index do |node, i|
      next if i == 0
      day, drink, food = node.children.text().strip().split("\n\t\t")
      
      puts "*** day: #{day}, drink: #{drink}, food: #{food}"
      
      if day.blank?
        puts "[error] special day is empty"
        next
      end

      # build recurrence rule from day
      rule      = "FREQ=WEEKLY;BYDAY=%s" % day.slice(0,2).upcase

      # build start_at, end_at from day
      start_at  = DateRange.find_next_date(day.downcase)
      end_at    = start_at.end_of_day

      # format drink and food strings
      drink     = normalize(drink)
      food      = normalize(food)

      if drink.blank? and food.blank?
        puts "[notice] no food or drink specials"
        next
      end

      # build special hash
      object    = Hash["rule" => rule, "start_at" => start_at, "end_at" => end_at]
      object["special_drink"] = drink unless drink.blank?
      object["special_food"]  = food unless food.blank?

      # puts object.inspect

      # add special
      added     = Special.add(location, object)
    end
  end
  
  def normalize(s)
    return s if s.blank?
    s.gsub(/none/i, '').strip
  end
  
end