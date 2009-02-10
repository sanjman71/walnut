class AddressArea < ActiveRecord::Base
  belongs_to              :area, :counter_cache => :addresses_count
  belongs_to              :address
  validates_presence_of   :area_id, :address_id
end