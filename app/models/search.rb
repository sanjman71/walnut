class Search
  attr_reader :locality_tags, :locality_hash, :place_tags
  
  @@anything_search = ["anything"]
  
  def initialize(options={})
    @locality_tags  = options[:locality_tags] || []
    @locality_hash  = options[:locality_hash] || Hash.new
    @place_tags     = options[:place_tags] || []
    
    # handle special anything search
    @place_tags     = [] if @place_tags == @@anything_search
  end

  # build query as an 'or' of each tag
  def query
    @place_tags.join(" | ")
  end
  
  def field(field)
    case field
    when :locality_tags, "locality_tags"
      @locality_tags.join(" ")
    when :locality_hash
      @locality_hash
    when :place_tags, "place_tags"
      @place_tags.join(" | ")
    else
      raise ArgumentError, "invalid field"
    end
  end
  
  def multiple_fields(*args)
    # sort fields
    fields      = Array(args).sort_by{|field| field.to_s}
    # build field set
    field_set   = "@(" + fields.join(",") + ")"
    # build field value from the individual fields
    field_value = fields.inject('') do |s, field_name|
      begin
        s += field(field_name)
      rescue
        # invalid field, skip it
      end
      s
    end
    
    if field_value.blank?
      # empty query
      ""
    else
      # build the final query from the field set and field value
      [field_set, field_value.strip].compact.join(" ").strip
    end
  end
  
  # parse search where and what values
  def self.parse(where_collection, what=nil)
    neighborhoods, others = Array(where_collection).compact.partition { |o| o.is_a?(Neighborhood) }

    locality_tags = (others + neighborhoods).inject([]) do |array, locality|
      array.push(locality.name) if locality
      array
    end
    
    # build locality hash from cities, states, zips countries
    locality_hash = others.inject(Hash.new) do |hash, locality|
      if locality
        # locality key looks like 'city_id', 'zip_id', 'state_id', 'country_id'
        key       = locality.class.to_s.foreign_key
        hash[key] = locality.id
      end
      hash
    end
    
    # add neighborhoods
    locality_hash = neighborhoods.inject(locality_hash) do |hash, neighborhood|
      if neighborhood
        key       = neighborhood.class.to_s.foreign_key + "s"
        hash[key] = neighborhood.id
      end
      hash
    end
    
    # split what into tokens
    place_tags = what.to_s.split
    
    Search.new(:locality_tags => locality_tags, :locality_hash => locality_hash, :place_tags => place_tags)
  end
  
  def self.with(*args)
    hash = Hash.new
    Array(args).compact.each do |locality|
      hash[class_to_attribute_symbol(locality.class)] = locality.id
    end
    hash
  end
  
  def self.tag_group_options(limit)
    # note: we need to set max_matches to override the per_page limit
    Hash[:facets => "tag_ids", :group_by => "tag_ids", :group_clause => "@count desc", :limit => limit.to_i, :max_matches => limit.to_i]
  end

  def self.city_group_options(limit)
    # note: we need to set max_matches to override the per_page limit
    Hash[:facets => "city_id", :group_by => "city_id", :group_clause => "@count desc", :limit => limit.to_i, :max_matches => limit.to_i]
  end

  def self.neighborhood_group_options(limit)
    # note: we need to set max_matches to override the per_page limit
    Hash[:facets => "neighborhood_ids", :group_by => "neighborhood_ids", :group_clause => "@count desc", :limit => limit.to_i, :max_matches => limit.to_i]
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
        # e.g. City facet key is :city_id
        objects.push(model.find(facets[class_to_attribute_symbol(model)].keys, :include => eager_load))
      when "Neighborhood", "EventCategory"
        # eager load associations
        eager_load.push(:city) if ["Neighborhood"].include?(model.to_s)
        # e.g. Neighborhood facet key is :neighborhood_ids
        objects.push(model.find(facets[class_to_attribute_symbol(model)].keys, :include => eager_load))
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
