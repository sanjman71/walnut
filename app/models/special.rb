class Special

  def self.find_all
    tag = Tag.find_by_name(tag_name)
    return [] if tag.blank?
    Appointment.public.recurring.all(:joins => :tags, :conditions => ["tags.id = ?", tag.id])
  end

  def self.find_by_city(city, options={})
    return [] if city.blank?
    tag = Tag.find_by_name(tag_name)
    return [] if tag.blank?
    # find public recurring appointments in the specified city
    Appointment.public.recurring.all(:joins => [:tags, :location], :conditions => ["locations.city_id = ? AND tags.id = ?", city.id, tag.id])
  end

  # find location specials for the specified day
  def self.find_by_day(location, day)
    # find tag 'day'
    tag = Tag.find_by_name(day)
    return [] if tag.blank?
    # find appointment tagged with tag
    Appointment.public.recurring.all(:joins => [:tags, :location], :conditions => ["locations.id = ? AND tags.id = ?", location.id, tag.id])
  end

  # returns true if the specified string is a valid day
  def self.day?(s)
    return false if s.blank?
    Recurrence::DAYS_OF_WEEK.values.include?(s.titleize)
  end

  # days supported
  def self.days
    ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
  end

  # normalize comma separated list into a collection
  def self.collectionize(s)
    s.split(/(\$[^\$]*,{0,1})/).reject(&:blank?).map{ |s| s.strip.gsub(/,/, '') }
  end

  # find today in long format, e.g. 'Sunday'
  def self.today
    Time.now.to_s(:appt_week_day_long)
  end
  
  def self.create(name, location, recur_rule, options={})
    company     = options[:company] || location.company
    start_at    = options[:start_at]
    end_at      = options[:end_at]
    tags        = Array(options[:tags] || [])
    preferences = options[:preferences] || Hash[]
    
    # create the special as a public, recurring appointment
    special = location.appointments.create(:name => name, :company => company, :recur_rule => recur_rule,
                                           :start_at => start_at, :end_at => end_at,
                                           :mark_as => Appointment::FREE, :public => true)

    # add 'special' tag
    tags.push(tag_name)

    if Recurrence.frequency(recur_rule) == 'weekly'
      # add day tags
      Recurrence.days(recur_rule, :format => :long).each do |day|
        tags.push(day.to_s.downcase)
      end
    end

    # add tags
    if !tags.empty?
      special.tag_list.add(tags)
      special.save
    end

    # add preferences
    unless preferences.empty?
      preferences.each_pair { |k, v| special.preferences[k] = v }
      special.save
    end
    
    special
  end
  
  def self.tag_name
    'special'
  end

  # find or create the 'Specials' event category
  def self.find_event_category
    options  = Hash[:name => event_category_name, :source_id => "0", :source_type => "Specials"]
    category = EventCategory.find_by_name(event_category_name) || EventCategory.create(options)
  end

  def self.event_category_name
    'Specials'
  end

  # return collection of special preferences
  def self.preferences(hash)
    hash.keys.inject(Hash[]) do |prefs, key|
      if match = key.to_s.match(/^special_(\w+)/)
        prefs[key] = hash[key]
      end
      prefs
    end
  end

  # return the preference name, without the leading 'special_' 
  def self.preference_name(s)
    match = s.to_s.match(/^special_(\w+)/)
    match ? match[1] : s
  end

  # import specials from specified yaml file
  def self.import(file = "data/specials.yml")
    s = YAML::load_stream( File.open(file))

    s.documents.each do |object|
      locations = match(object)
      
      if locations.blank?
        puts "[error] no match"
        next
      elsif locations.size > 1
        puts "[error] too many matches"
        next
      end

      location = locations.first

      puts "*** matched location #{location.id}:#{location.company_name}"

      added   = add(location, object)
    end
  end

  def self.add(location, object)
    # check rule
    rule = object["rule"]
    days = Recurrence.days(rule, :format => :long)

    if days.empty?
      puts "[error] recurrence rule has no days"
      raise Exception, "invalid recurrence"
    end

    added       = 0
    preferences = Special.preferences(object)

    # puts "*** preferences: #{preferences.inspect}"

    days.each do |day|
      # check any existing day specials
      specials   = Special.find_by_day(location, day.downcase)
      next if !specials.empty?
      puts "[ok] adding #{day.downcase} special"
      title      = object["title"] ? object['title'] : 'Special'
      start_at   = DateRange.find_next_date(day.downcase)
      end_at     = start_at.end_of_day
      special    = Special.create(title, location, rule, :start_at => start_at, :end_at => end_at, :preferences => preferences)
      added      += 1
    end

    added
  end
  
  def self.match(object)
    @name           = object['name'] # e.g. kerryman
    @state          = object["state"] # e.g. il
    @city           = object['city'] # e.g. chicago
    @phone          = object['phone'] # e.g. 3125559999
    @address        = object['address'] # e.g. 14 Division

    # find state, city
    @state          = State.find_by_code(@state.upcase)
    @city           = @state.cities.find_by_name(@city) if @state
    
    if @city.blank?
      puts "[error] missing city"
      return []
    end

    # search city
    @attributes     = Search.attributes(@city)

    # only search locations
    @klasses        = [Location]
    @sort_order     = "popularity desc, @relevance desc"

    puts "*** searching using name and address"

    # search query using a field search for name and address
    @query          = ["name:'#{@name}'", @address ? "address:'#{@address}'" : ''].reject(&:blank?).join(' ')
    @hash           = Search.query(@query)
    @fields         = @hash[:fields]

    @sphinx_options = Hash[:classes => @klasses, :with => @attributes, :conditions => @fields, :order => @sort_order,
                           :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5, :max_matches => 100]

    @locations      = ThinkingSphinx.search(@sphinx_options)

    if @locations.size > 1 and !@phone.blank?
      puts "*** searching using name and phone"
      # try again with name and phone
      @query          = ["name:'#{@name}'", "phone:'#{@phone}'"].join(' ')
      @hash           = Search.query(@query)
      @fields         = @hash[:fields]

      @sphinx_options = Hash[:classes => @klasses, :with => @attributes, :conditions => @fields, :order => @sort_order,
                             :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5, :max_matches => 100]

      @locations      = ThinkingSphinx.search(@sphinx_options)
    end
    
    @locations
  end
end