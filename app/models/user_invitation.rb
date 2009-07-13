module UserInvitation
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
      
      has_many      :sent_invitations, :class_name => 'Invitation'
      has_many      :received_invitations, :class_name => 'Invitation'
    end
  end

  module ClassMethods
  end # class methods
  
  module InstanceMethods
  end # instance methods
end