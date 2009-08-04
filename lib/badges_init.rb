module BadgesInit
  
  def self.roles_privileges
    # initialize basic roles and privileges
    user  = Badges::Role.find_by_name(Badges::Config.default_user_role.to_s) || Badges::Role.create(:name=>Badges::Config.default_user_role.to_s)
    admin = Badges::Role.find_by_name(Badges::Config.default_admin_role.to_s) || Badges::Role.create(:name=>Badges::Config.default_admin_role.to_s)
    
    # admins can manage the site
    ms    = Badges::Privilege.find_by_name("manage site") || Badges::Privilege.create(:name => "manage site")
  end
  
end