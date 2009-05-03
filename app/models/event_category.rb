class EventCategory < ActiveRecord::Base
  validates_presence_of     :name, :source_type, :source_id
  validates_uniqueness_of   :name
  
  has_many                  :event_category_mappings, :dependent => :destroy
  has_many                  :events, :through => :event_category_mappings
  
  named_scope :popular,         { :conditions => ["popularity > 0"] }
  named_scope :order_by_name,   { :order => "name ASC" }
  
  def to_param
    self.source_id.dasherize
  end
  
  # convert object to a string of attributes separated by '|'
  def to_pipe
    [self.name, self.tags].join("|")
  end
  
end
  