class AddressAddressable < ActiveRecord::Base
  belongs_to              :addressable, :polymorphic => true, :counter_cache => :addresses_count
  belongs_to              :address
end