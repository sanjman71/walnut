class CreateBadges < ActiveRecord::Migration
  def self.up
    create_table :badges_roles, :force => true do |t|
      t.string :name,               :string, :limit => 50

      t.timestamps
      t.integer :lock_version, :default => 0, :null => false
    end
    
    add_index :badges_roles, [:name]
    
    create_table :badges_user_roles, :force => true  do |t|
      t.column :user_id,            :integer
      t.column :role_id,            :integer
      t.column :authorizable_type,  :string, :limit => 30
      t.column :authorizable_id,    :integer

      t.timestamps
      t.integer :lock_version, :default => 0, :null => false
    end

    add_index :badges_user_roles, [:authorizable_type, :authorizable_id], :name => "index_on_authorizable"
    add_index :badges_user_roles, [:user_id, :role_id, :authorizable_type, :authorizable_id], :name => "index_on_user_roles_authorizable"

    create_table :badges_privileges, :force => true do |t|
      t.column :name,               :string, :limit => 50

      t.timestamps
      t.integer :lock_version, :default => 0, :null => false
    end

    add_index :badges_privileges, [:name]

    create_table :badges_role_privileges, :force => true  do |t|
      t.column :role_id,            :integer
      t.column :privilege_id,       :integer

      t.timestamps
      t.integer :lock_version, :default => 0, :null => false
    end

    add_index :badges_role_privileges, [:role_id]
    add_index :badges_role_privileges, [:privilege_id]
    add_index :badges_role_privileges, [:privilege_id, :role_id]

    Badges::Role.create(:name=>Badges::Config.default_user_role.to_s)
    Badges::Role.create(:name=>Badges::Config.default_admin_role.to_s)
  end

  def self.down
    Badges::Role.find(:first, :conditions=>{:name=>Badges::Config.default_user_role.to_s}).destroy
    Badges::Role.find(:first, :conditions=>{:name=>Badges::Config.default_admin_role.to_s}).destroy

    drop_table :badges_role_privileges
    drop_table :badges_privileges
    drop_table :badges_user_roles
    drop_table :badges_roles
  end
end
