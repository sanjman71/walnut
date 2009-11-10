class AddPeanutIndexes < ActiveRecord::Migration
  def self.up
    add_index :companies, :subdomain
    add_index :companies, :chain_id
    add_index :chains, :companies_count
    add_index :subscriptions, :company_id
    add_index :email_addresses, :address

    # make sure index is normal, not unique
    remove_index :logos, :company_id
    add_index    :logos, :company_id

    # add column limits
    change_column :services, :mark_as, :string, :limit => 50
    change_column :company_providers, :provider_type, :string, :limit => 50
  end

  def self.down
    remove_index :companies, :subdomain
    remove_index :companies, :chain_id
    remove_index :chains, :companies_count
    remove_index :subscriptions, :company_id
    remove_index :email_addresses, :address
  end
end
