module Badges
  class Role < ActiveRecord::Base
    set_table_name "badges_roles"

    validates_uniqueness_of :name, :case_sensitive => false
    
    has_many :user_roles, :class_name=>'Badges::UserRole', :dependent => :destroy
    has_many :role_privileges, :class_name=>'Badges::RolePrivilege', :dependent => :destroy
    has_many :privileges, :through=>:role_privileges, :class_name=>'Badges::Privilege'    
    
    def includes_privilege?(privilege)
      !privileges.find_by_name(privilege).nil?
    end
    
  end
end