class CreatePeanut < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string  :name
      t.string  :time_zone
      t.string  :subdomain
      t.string  :slogan
      t.text    :description
      t.integer :locations_count, :default => 0       # counter cache
      t.integer :services_count, :default => 0        # counter cache
      t.integer :work_services_count, :default => 0   # counter cache
      t.integer :providers_count, :default => 0       # counter cache
      t.timestamps
    end
    
    add_index :companies, [:subdomain]
    
    create_table :services do |t|
      t.string  :name
      t.integer :duration
      t.string  :mark_as
      t.integer :price_in_cents
      t.integer :providers_count, :default => 0             # counter cache
      t.boolean :allow_custom_duration, :default => false   # by default no custom duration
      
      t.timestamps
    end

    add_index :services, [:mark_as]

    # map services to companies
    create_table :company_services do |t|
      t.integer :company_id
      t.integer :service_id
    end

    add_index :company_services, [:company_id]
    add_index :company_services, [:service_id]
    
    create_table :products do |t|
      t.integer   :company_id
      t.string    :name
      t.integer   :inventory
      t.integer   :price_in_cents
      t.timestamps
    end
  
    add_index :products, [:company_id]
    add_index :products, [:company_id, :name]

    # Map polymorphic providers (e.g. users) to companies
    create_table :company_providers do |t|
      t.references  :company
      t.references  :provider, :polymorphic => true
      t.timestamps
    end
    
    add_index :company_providers, [:provider_id, :provider_type], :name => 'index_on_providers'
    add_index :company_providers, [:company_id, :provider_id, :provider_type], :name => 'index_on_companies_and_providers'

    # Polymorphic relationship mapping services to provider (e.g. users, things)
    create_table :service_providers do |t|
      t.references  :service
      t.references  :provider, :polymorphic => true
      t.timestamps
    end

    add_index :service_providers, [:service_id, :provider_id, :provider_type], :name => 'index_on_services_and_providers'
    
    create_table :resources do |t|
      t.string  :name
      t.string  :description
    end
    
    add_index :resources, [:name]
    
    create_table :appointments do |t|
      t.integer     :company_id
      t.integer     :service_id
      t.references  :provider, :polymorphic => true    # e.g. users
      t.integer     :customer_id       # user who booked the appointment
      t.string      :when
      t.datetime    :start_at
      t.datetime    :end_at
      t.integer     :duration
      t.string      :time
      t.integer     :time_start_at  # time of day
      t.integer     :time_end_at    # time of day
      t.string      :mark_as
      t.string      :state
      t.string      :confirmation_code
      t.integer     :locations_count, :default => 0     # locations counter cache
      t.datetime    :canceled_at
      t.timestamps
    end

    add_index :appointments, [:company_id, :start_at, :end_at, :duration, :time_start_at, :time_end_at, :mark_as], :name => "index_on_openings"
    
    create_table :invoice_line_items do |t|
      t.integer     :invoice_id
      t.references  :chargeable, :polymorphic => true
      t.integer     :price_in_cents
      t.integer     :tax
      t.timestamps
    end
    
    create_table :invoices do |t|
      t.references  :invoiceable, :polymorphic => true
      t.integer     :gratuity_in_cents
      t.timestamps
    end
    
    create_table :notes do |t|
      t.text  :comment
      t.timestamps
    end
    
    # Polymorphic relationship mapping notes to different subjects (e.g. people, appointments)
    create_table :notes_subjects do |t|
      t.references  :note
      t.references  :subject, :polymorphic => true
    end
    
    create_table :invitations do |t|
      t.integer   :sender_id
      t.integer   :recipient_id
      t.string    :recipient_email
      t.string    :token
      t.string    :role
      t.datetime  :sent_at
      t.integer   :company_id
      
      t.timestamps
    end
    
    add_index :invitations, :token
  end

  def self.down
    drop_table :invitations
    drop_table :notes_subjects
    drop_table :notes
    drop_table :invoices
    drop_table :invoice_line_items
    drop_table :appointments
    drop_table :resources
    drop_table :service_providers
    drop_table :company_providers
    drop_table :products
    drop_table :company_services
    drop_table :services
    drop_table :companies
  end
end



