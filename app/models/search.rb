class Search
  
  @@anything_search = "anything"
  
  # normalize the string
  def self.normalize(s)
    # remove quotes, dashes, @
    s.gsub(/['-@]/, '').strip
  end
  
  # build sphinx attributes
  def self.attributes(*args)
    hash = Hash.new
    Array(args).compact.each do |locality|
      hash[class_to_attribute_symbol(locality.class)] = locality.id
    end
    hash
  end
  
  def self.query(s)
    hash        = Hash[:query_raw => s]
    fields      = Hash.new
    attributes  = Hash.new
    
    # valid fields and attributes
    all_fields      = [:address, :name, :tags]
    all_attributes  = [:events, :popularity]
    
    # valid patterns
    match_token     = "([a-zA-Z]+):([0-9a-zA-Z]+)"
    match_quotes    = "([a-zA-Z]+):'([0-9a-zA-Z ]+)'"

    while true
      if matches = s.match(/#{match_token}/)
        key   = matches[1].to_sym
        value = matches[2]
      
        # removed matched string
        s = s.gsub(/#{match_token}/, '').strip
      elsif matches = s.match(/#{match_quotes}/)
        key   = matches[1].to_sym
        value = matches[2]

        # removed matched string
        s = s.gsub(/#{match_quotes}/, '').strip
      else
        # no (more matches)
        break
      end
    
      if all_attributes.include?(key)
        case key
        when :events, :popularity
          # value should be an int or a range
          if value.to_i > 0
            value = value.to_i..2**30
          else
            value = 0
          end
          attributes[key] = value
        else
          attributes[key] = value
        end
      elsif all_fields.include?(key)
        # fields are usually strings
        fields[key] = value.to_s
      end
    end
    
    # check for special anything search
    s = s.gsub(@@anything_search, '')
    
    # add query, both as default with implicity 'and' operator and explicit 'or' operator
    tokenized           = normalize(s).strip.split#.map{ |s| s = normalize(s) }.compact
    hash[:query_and]    = tokenized.join(" ")
    hash[:query_or]     = tokenized.join(" | ")
    
    # add fields and attribuutes
    hash[:attributes]   = attributes unless attributes.empty?
    hash[:fields]       = fields unless fields.blank?
    
    hash
  end
  
  # load the specified model(s) from the facets collection
  def self.load_from_facets(facets, models=[])
    return [] if models.blank?
    
    objects     = []
    eager_load  = []
    
    Array(models).each do |model|
      case model.to_s
      when "City", "Zip", "State", "Country"
        # eager load associations
        eager_load.push(:state) if ["City", "Zip"].include?(model.to_s)
        # e.g. City facet key is :city_id; remove invalid keys
        objects.push(model.find(facets[class_to_attribute_symbol(model)].keys.zero_compact!, :include => eager_load))
      when "Neighborhood", "EventCategory"
        # eager load associations
        eager_load.push(:city) if ["Neighborhood"].include?(model.to_s)
        # e.g. Neighborhood facet key is :neighborhood_ids; remove invalid keys
        objects.push(model.find(facets[class_to_attribute_symbol(model)].keys.zero_compact!, :include => eager_load))
      when "Tag"
        # load tags and build tag counts
        tag_ids = facets[class_to_attribute_symbol(model)]
        tags    = model.find(tag_ids.keys)
        # set tag.taggings_count to faceted value, and freeze tag objects
        tags.each do |tag|
          tag.taggings_count = tag_ids[tag.id]
          tag.freeze
        end
        objects.push(tags)
      else
        
      end
    end
    
    objects.size == 1 ? objects.flatten : objects
  end
  
  protected
  
  # convert class to a search attribute symbol
  #  - e.g. City to :city_id, Neighborhood to :neigborhoods_id
  def self.class_to_attribute_symbol(model)
    case model.to_s
    when "City", "Zip", "State", "Country"
      model.to_s.foreign_key.to_sym
    when "Neighborhood", "Tag", "EventCategory"
      model.to_s.foreign_key.pluralize.to_sym
    end
  end
  
end
