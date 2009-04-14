module UserSharedAuthentication
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
    base.establish_connection("shared_authentication_#{RAILS_ENV}")
  end

  module ClassMethods
  end # class methods
  
  module InstanceMethods
  end # instance methods
end