class EmailAddress < ActiveRecord::Base
  validates_presence_of     :address, :priority
  validates_presence_of     :emailable, :polymorphic => true
  validates_length_of       :address,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :address,    :case_sensitive => false
  validates_format_of       :address,    :with => Authentication.email_regex, :message => Authentication.bad_email_message
  validates_uniqueness_of   :address, :scope => [:emailable_id, :emailable_type]
  belongs_to                :emailable, :polymorphic => true, :counter_cache => :email_addresses_count
  
  named_scope               :with_emailable_type, lambda { |t| { :conditions => {:emailable_type => t} } }

  def before_validation_on_create
    # set default priority
    self.priority = 1 if self.priority.blank?
  end

end