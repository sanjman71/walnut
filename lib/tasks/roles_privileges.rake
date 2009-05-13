namespace :rp do
  
  desc "Initialize roles and privileges"
  task :init => [:admins, :tag_groups, :tags]

  desc "Initialize admin users roles and privileges"
  task :admins do
    puts "#{Time.now}: initializing admin users"
    
    u = User.find_by_name("Admin Killian")
    u.grant_role('admin') unless u.blank?

    u = User.find_by_name("Admin Sanjay")
    u.grant_role('admin') unless u.blank?
    
    # create admin privileges
    Badges::Privilege.create(:name=>"manage site")
  end
  
  desc "Initialize tag groups roles and privileges"
  task :tag_groups do 
    ctg = Badges::Privilege.create(:name=>"create tag groups")
    rtg = Badges::Privilege.create(:name=>"read tag groups")
    utg = Badges::Privilege.create(:name=>"update tag groups")
    dtg = Badges::Privilege.create(:name=>"delete tag groups")
  end

  desc "Initialize tags roles and privileges"
  task :tags do 
    ct = Badges::Privilege.create(:name=>"create tags")
    rt = Badges::Privilege.create(:name=>"read tags")
    ut = Badges::Privilege.create(:name=>"update tags")
    dt = Badges::Privilege.create(:name=>"delete tags")
  end
  
end
