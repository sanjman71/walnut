class PhoneNumber < ActiveRecord::Base
  validates_presence_of   :name, :number
  validates_format_of     :number, :with => /[0-9]{10,11}/
  belongs_to              :callable, :polymorphic => true, :counter_cache => :phone_numbers_count
end