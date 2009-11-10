class Chain < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name
  has_many                  :companies
  serialized_hash           :states, Hash[]

  include NameParam

  # used to generated an seo friendly url parameter
  acts_as_friendly_param    :name
  
  named_scope :no_companies,        { :conditions => {:companies_count => 0} }
  named_scope :with_companies,      { :conditions => ["companies_count > 0"] }
  named_scope :order_by_company,    { :order => 'companies_count desc' }

  named_scope :starts_with,         lambda { |s| { :conditions => ["display_name LIKE ?", s + '%'] } }

  def display_name
    @display_name = read_attribute(:display_name)
    @display_name.blank? ? read_attribute(:name) : @display_name
  end

  # find all chain first letters, digits
  def self.alphabet
    self.all(:select => "display_name").collect{ |o| o.display_name ? o.display_name.first.upcase : nil}.compact.uniq.sort
  end
end