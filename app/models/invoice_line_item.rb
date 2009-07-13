class InvoiceLineItem < ActiveRecord::Base
  belongs_to                :chargeable, :polymorphic => true
  belongs_to                :invoice
  validates_presence_of     :invoice_id, :price_in_cents, :chargeable_type, :chargeable_id
end