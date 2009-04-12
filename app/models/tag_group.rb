class TagGroup < ActiveRecord::Base
  validates_presence_of       :name
  validates_uniqueness_of     :name
  has_many                    :place_tag_groups
  has_many                    :places, :through => :place_tag_groups, :after_add => :after_add_place, :after_remove => :after_remove_place
  
  named_scope                 :search_name,           lambda { |s| {:conditions => ["name REGEXP '%s'", s] }}
  named_scope                 :search_name_and_tags,  lambda { |s| {:conditions => ["name REGEXP '%s' OR tags REGEXP '%s'", s, s] }}
  
  # find tag groups with no tags
  named_scope                 :empty,                 { :conditions => ["tags = '' OR tags IS NULL"] }
  
  named_scope                 :order_by_name,         { :order => "name ASC" }
  
  def after_initialize
    # after_initialize can also be called when retrieving objects from the database
    return unless new_record?

    # initialize applied_at timestamp for new objects
    self.applied_at = Time.now
  end
   
  def name=(s)
    return if s.blank?
    # capitalize words, except for 'and', 'or'
    s = s.split.map{ |s| ['and', 'or'].include?(s.downcase) ? s : s.capitalize }.join(" ")
    write_attribute(:name, s)
  end
  
  # tags can be a comma separated list or an array
  def tags=(s)
    s = validate_and_clean_string(s)
    write_attribute(:tags, s.join(","))
  end

  # tags to add as a comma separated list or an array
  def add_tags(s)
    s = validate_and_clean_string(s)
    t = tag_list
    s = (t + s).uniq.sort
    # keep track of recently added tags
    write_attribute(:recent_add_tags, (s-t).join(",")) 
    write_attribute(:tags, s.join(","))
  end
  
  # tags to remove as a comma separated list or an array
  def remove_tags(s)
    s = validate_and_clean_string(s)
    t = tag_list
    s = (t - s).uniq.sort
    # keep track of recently removed tags
    write_attribute(:recent_remove_tags, (t-s).join(",")) 
    write_attribute(:tags, s.join(","))
  end
  
  # build the tag list array from the tags string
  def tag_list
    Array.new(self.tags ? self.tags.split(",") : [])
  end 
  
  def recent_add_tag_list
    Array.new(self.recent_add_tags ? self.recent_add_tags.split(",") : [])
  end

  def recent_remove_tag_list
    Array.new(self.recent_remove_tags ? self.recent_remove_tags.split(",") : [])
  end
  
  # (re-)apply tags to all places
  def apply
    places.each { |place| apply_tags(place) }
    # update applied_at timestamp
    update_attribute(:applied_at, Time.now)
  end
  
  def dirty?
    self.applied_at < self.updated_at
  end
  
  # convert tag group to a string of attributes separated by '|'
  def to_pipe
    [self.id, self.name, self.tags].join("|")
  end
  
  protected
  
  def validate_and_clean_string(s)
    raise ArgumentError, "expected String or Array" unless [String, Array].include?(s.class)
    
    case s.class.to_s
    when "String"
      s = clean(s.split(","))
    when "Array"
      s = clean(s)
    end
    s
  end
  
  def clean(array)
    array.reject(&:blank?).map{|s| s.downcase.strip }.uniq.sort
  end
  
  def apply_tags(place)
    return false if place.blank?
    place.tag_list.add(tag_list)
    place.save
  end
  
  def after_add_place(place)
    apply_tags(place)
  end
  
  def after_remove_place(place)
    return if place.blank?
    place.tag_list.remove(tag_list)
    place.save
    
    # decrement places_count counter cache
    # TODO: find out why the built-in counter cache doesn't work here
    TagGroup.decrement_counter(:places_count, id)
  end
end