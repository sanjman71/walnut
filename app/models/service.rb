class Service < ActiveRecord::Base
  belongs_to                  :company
  validates_presence_of       :name, :company_id, :price_in_cents
  validates_presence_of       :duration, :if => :duration_required?
  validates_presence_of       :capacity
  validates_numericality_of   :capacity
  validates_inclusion_of      :duration, :in => 1..(7.days), :message => "must be a non-zero reasonable value", :if => :duration_required?
  validates_inclusion_of      :mark_as, :in => %w(free work), :message => "can only be scheduled as free or work"
  validates_uniqueness_of     :name, :scope => :company_id
  has_many                    :appointments
  has_many                    :service_providers, :dependent => :destroy
  has_many                    :user_providers, :through => :service_providers, :source => :provider, :source_type => 'User',
                              :after_add => :after_add_provider, :after_remove => :after_remove_provider
  has_many                    :resource_providers, :through => :service_providers, :source => :provider, :source_type => 'Resource',
                              :after_add => :after_add_provider, :after_remove => :after_remove_provider
  before_save                 :titleize_name
  
  # name constants
  AVAILABLE                   = "Available"
  UNAVAILABLE                 = "Unavailable"
  
  # find services by mark as type
  Appointment::MARK_AS_TYPES.each { |s| named_scope s, :conditions => {:mark_as => s} }
  
  # find services with at least 1 service provider
  named_scope :with_providers,  { :conditions => ["providers_count > 0"] }
  
  def self.nothing(options={})
    r = Service.new do |o|
      o.name = options[:name] || ""
      o.send(:id=, 0)
      o.duration = 0
      o.allow_custom_duration = false
    end
  end
    
  # return true if its the special service 'nothing'
  def nothing?
    self.id == 0
  end

  # Virtual attribute for use in the UI - entering the lenght of the service is done in minutes rather than seconds. This converts in both directions
  def duration_in_minutes
    (self.duration.to_i / 60).to_i
  end
  
  def duration_in_minutes=(duration_in_minutes)
    duration_will_change!
    self.duration = duration_in_minutes.to_i.minutes
  end

  # find all polymorphic providers through the company_providers collection
  def providers
    self.service_providers(:include => :provider).collect(&:provider)
  end

  # return true if the service is provided by the specfied provider
  def provided_by?(o)
    self.providers.include?(o)
  end

  def free?
    self.mark_as == Appointment::FREE
  end

  def work?
    self.mark_as == Appointment::WORK
  end

  private
  
  # durations are required for work services
  def duration_required?
    return true if work?
    false
  end
  
  def titleize_name
    self.name = self.name.titleize
  end
  
  def after_add_provider(provider)
  end

  def after_remove_provider(provider)
    # the decrement counter cache doesn't work, so decrement here
    Service.decrement_counter(:providers_count, self.id) if provider
  end
end
