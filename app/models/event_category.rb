class EventCategory < ActiveRecord::Base
  validates_presence_of     :name, :source_type, :source_id
  validates_uniqueness_of   :name
  
  named_scope :popular,         { :conditions => ["popularity > 0"] }
  named_scope :order_by_name,   { :order => "name ASC" }
  
  def to_param
    self.source_id.dasherize
  end
end
  