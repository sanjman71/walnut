class PhoneNumber < ActiveRecord::Base
  validates_presence_of     :callable, :polymorphic => true
  validates_presence_of     :name, :address
  validates_format_of       :address, :with => /[0-9]{10,11}/
  validates_uniqueness_of   :address, :scope => [:callable_id, :callable_type]
  before_validation         :format_phone
  belongs_to                :callable, :polymorphic => true, :counter_cache => :phone_numbers_count
  
  named_scope               :with_callable_type, lambda { |t| { :conditions => {:callable_type => t} } }

  def before_validation_on_create
    # set default priority
    self.priority = 1 if self.priority.blank?
  end
  
  protected
  
  # format phone by removing all non-digits
  def format_phone
    self.address.gsub!(/[^\d]/, '') unless self.address.blank?
  end

end