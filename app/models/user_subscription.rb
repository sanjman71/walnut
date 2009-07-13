module UserSubscription
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
      
      # user can have many subscriptions, plans, and companies
      has_many    :subscriptions
      has_many    :plans, :through => :subscriptions
      has_many    :companies, :through => :subscriptions, :source => :company
    end
  end

  module ClassMethods
  end # class methods
  
  module InstanceMethods
  end # instance methods
end