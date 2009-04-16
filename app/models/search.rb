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
    locality_tags = Array(where_collection).compact.inject([]) do |array, locality|
      array.push(locality.name) if locality
      array
    end
    
    locality_hash = Array(where_collection).compact.inject(Hash.new) do |hash, locality|
      if locality
        # locality key looks like 'city_id', 'zip_id', 'state_id', ...
        key       = locality.class.to_s.foreign_key
        hash[key] = locality.id
      end
      hash
    end
    
    # split what into tokens
    place_tags = what.to_s.split
    
    Search.new(:locality_tags => locality_tags, :locality_hash => locality_hash, :place_tags => place_tags)
  end
end