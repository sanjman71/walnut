class Resource < ActiveRecord::Base
  validates_presence_of     :name
  
  has_many                  :company_providers, :as => :provider, :dependent => :destroy
  has_many                  :companies, :through => :company_providers, :source => :company

  # Appointments associations
  # TODO - what happens when the resource goes away?
  has_many                  :appointments, :as => :provider
  has_many                  :capacity_slots, :as => :provider

  named_scope               :order_by_name, { :order => 'resources.name' }
    
  # return true if its the special user 'anything'
  def anything?
    self.id == 0
  end

  alias :anyone? :anything?
  
  def tableize
    self.class.to_s.tableize
  end

  # resources do not have email addresses
  def email_addresses_count
    0
  end

end