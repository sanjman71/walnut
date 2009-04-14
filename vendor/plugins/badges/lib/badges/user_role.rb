module Badges
  class UserRole < ActiveRecord::Base
    set_table_name "badges_user_roles"

    belongs_to :authorizable, :polymorphic => true
    belongs_to :role, :class_name=>"Badges::Role", :foreign_key=>'role_id'

    belongs_to :user, :class_name=>"User", :foreign_key=>'user_id'
    
  end
end