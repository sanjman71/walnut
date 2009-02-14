class Search
  attr_reader :locality_tags, :place_tags
  
  def initialize(options={})
    @locality_tags  = options[:locality_tags] || []
    @place_tags     = options[:place_tags] || []
  end
  
  def field_for(field)
    case field
    when :locality_tags, "locality_tags"
      @locality_tags.join(" ")
    when :place_tags, "place_tags"
      @place_tags.join(" || ")
    else
      raise ArgumentError, "invalid field"
    end
  end
  
  # parse search localities and tags into a search object
  def self.parse(localities, tags=nil)
    locality_tags = Array(localities).compact.inject([]) do |array, locality|
      array.push(locality.name) if locality
      array
    end
    
    # split tags into tokens
    place_tags = tags.to_s.split
    
    Search.new(:locality_tags => locality_tags, :place_tags => place_tags)
  end
end