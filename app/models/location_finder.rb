class LocationFinder

  @@mappings = nil

  # define set of key to id mappings used to help in the matching process
  def self.mappings
    if @@mappings.blank?
      puts "*** loading mappings"
      s = YAML::load_stream(File.open("data/location_finder.yml"))
      @@mappings = s.documents
      # @@mappings = s.documents.inject(Hash[]) do |hash, document|
      #   hash.merge!(document)
      #   hash
      # end
    end
    @@mappings
  end
  
  # use sphinx to match the specified object hash to an existing location
  def self.match(object, options={})
    @name           = object['name'] # e.g. kerryman
    @state          = object["state"] # e.g. il
    @city           = object['city'] # e.g. chicago
    @phone          = object['phone'] # e.g. 3125559999
    @address        = object['address'] # e.g. 14 Division

    @log            = options[:log].to_i == 1

    puts "*** object: #{object.inspect}" if @log

    # find state, city
    @state          = State.find_by_code(@state.upcase)

    if @state.blank?
      puts "[error] missing state" if @log
      return []
    end

    @city           = @state.cities.find_by_name(@city)

    if @city.blank?
      puts "[error] missing city" if @log
      return []
    end

    # search city
    @attributes     = Search.attributes(@city)

    # only search locations
    @klasses        = [Location]
    @sort_order     = "popularity desc, @relevance desc"

    puts "*** searching using name and address" if @log

    # search query using a field search for name and address
    @query          = ["name:'#{@name}'", @address ? "address:'#{@address}'" : ''].reject(&:blank?).join(' ')
    @hash           = Search.query(@query)
    @fields         = @hash[:fields]

    @sphinx_options = Hash[:classes => @klasses, :with => @attributes, :conditions => @fields, :order => @sort_order,
                           :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5, :max_matches => 100]

    @locations      = ThinkingSphinx.search(@sphinx_options)

    if @locations.size != 1 and !@phone.blank?
      puts "*** searching using name and phone" if @log
      # try again with name and phone
      @query          = ["name:'#{@name}'", "phone:'#{@phone}'"].join(' ')
      @hash           = Search.query(@query)
      @fields         = @hash[:fields]

      @sphinx_options = Hash[:classes => @klasses, :with => @attributes, :conditions => @fields, :order => @sort_order,
                             :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5, :max_matches => 100]

      @locations      = ThinkingSphinx.search(@sphinx_options)
    end

    if @locations.size != 1 and !@phone.blank?
      puts "*** searching using phone" if @log
      # try again with just phone
      @query          = ["phone:'#{@phone}'"].join(' ')
      @hash           = Search.query(@query)
      @fields         = @hash[:fields]

      @sphinx_options = Hash[:classes => @klasses, :with => @attributes, :conditions => @fields, :order => @sort_order,
                             :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5, :max_matches => 100]

      @objects        = ThinkingSphinx.search(@sphinx_options)

      if @objects.size == 1
        # there was 1 phone match, but we require a phone and name match, so check object name with query name
        @object = @objects.first
        if (@object.company_name =~ /#{@name}/) || (@name =~ /#{@object.company_name}/)
          @locations = @objects
        end
      end
    end

    if @locations.size == 1
      location = @locations.first
      puts "[found] #{Hash["name" => location.company_name, "address" => location.street_address, "city" => location.city.name].inspect}" if @log
    end

    @locations
  end
  
  # use sphinx to match location on a phone number
  def self.match_phone(object, options={})
    @state          = object["state"] # e.g. il
    @city           = object['city'] # e.g. chicago
    @phone          = object['phone'] # e.g. 3125559999

    @log            = options[:log].to_i == 1

    puts "*** object: #{object.inspect}" if @log

    # find state, city
    @state          = State.find_by_code(@state.upcase)

    if @state.blank?
      puts "[error] missing state" if @log
      return []
    end

    @city           = @state.cities.find_by_name(@city)

    if @city.blank?
      puts "[error] missing city" if @log
      return []
    end

    # search city
    @attributes     = Search.attributes(@city)

    # only search locations
    @klasses        = [Location]
    @sort_order     = "popularity desc, @relevance desc"


    @query          = ["phone:'#{@phone}'"].join(' ')
    @hash           = Search.query(@query)
    @fields         = @hash[:fields]

    @sphinx_options = Hash[:classes => @klasses, :with => @attributes, :conditions => @fields, :order => @sort_order,
                           :match_mode => :extended2, :rank_mode => :bm25, :page => 1, :per_page => 5, :max_matches => 100]

    @objects        = ThinkingSphinx.search(@sphinx_options)
    @objects
  end
end