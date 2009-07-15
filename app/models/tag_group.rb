class TagGroup < ActiveRecord::Base
  validates_presence_of       :name
  validates_uniqueness_of     :name
  has_many                    :company_tag_groups
  has_many                    :companies, :through => :company_tag_groups, :after_add => :after_add_company, :after_remove => :after_remove_company
  
  named_scope                 :search_name,           lambda { |s| {:conditions => ["name REGEXP '%s'", s] }}
  named_scope                 :search_name_and_tags,  lambda { |s| {:conditions => ["name REGEXP '%s' OR tags REGEXP '%s'", s, s] }}
  
  # find tag groups with no tags
  named_scope                 :empty, { :conditions => ["tags = '' OR tags IS NULL"] }
  
  named_scope                 :order_by_name, { :order => "name ASC" }
  named_scope                 :order_by_companies_count, { :order => "companies_count DESC" }
  
  # tags have a limited word length
  TAG_MAX_WORDS = 3
  
  def self.to_csv
    csv = TagGroup.all.collect do |o|
      "#{o.id}|#{o.name}|#{o.tags}"
    end
  end
    
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
    s = TagGroup::validate_and_clean_string(s)
    write_attribute(:tags, s.join(","))
  end

  # tags to add as a comma separated list or an array
  def add_tags(s)
    s = TagGroup::validate_and_clean_string(s)
    t = tag_list
    s = (t + s).uniq.sort
    # keep track of recently added tags
    write_attribute(:recent_add_tags, (s-t).join(",")) 
    write_attribute(:tags, s.join(","))
  end
  
  # tags to remove as a comma separated list or an array
  def remove_tags(s)
    s = TagGroup::validate_and_clean_string(s)
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
  
  # (re-)apply tags to all companies
  def apply
    companies.each { |company| apply_tags(company) }
    # update applied_at timestamp
    update_attribute(:applied_at, Time.now)
  end
  
  def dirty?
    self.applied_at < self.updated_at
  end
  
  # convert tag group to a string of attributes separated by '|'
  def to_csv
    [self.id, self.name, self.tags].join("|")
  end
  
  protected
  
  def self.validate_and_clean_string(s)
    raise ArgumentError, "expected String or Array" unless [String, Array].include?(s.class)
    
    case s.class.to_s
    when "String"
      s = clean(s.split(","))
    when "Array"
      s = clean(s)
    end
    s
  end
  
  def self.clean(array)
    array.reject(&:blank?).map{|s| s.split(/\S+/).size > TAG_MAX_WORDS ? nil : s.downcase.strip }.compact.uniq.sort
  end
  
  def apply_tags(place)
    return false if place.blank?
    place.tag_list.add(tag_list)
    place.save
  end
  
  def after_add_company(company)
    apply_tags(company)
  end
  
  def after_remove_company(company)
    return if company.blank?
    company.tag_list.remove(tag_list)
    company.save
    
    # decrement companies_count counter cache
    # TODO: find out why the built-in counter cache doesn't work here
    TagGroup.decrement_counter(:companies_count, id)
  end
end