module UserAuthIdentity
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
  end

  module ClassMethods
  end # class methods

  module InstanceMethods
    def password_required?
      # no password required if using rpx
      return false if self.rpx == 1
      super
    end
  end # instance methods
end
