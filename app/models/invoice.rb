class Invoice < ActiveRecord::Base
  belongs_to                :invoiceable, :polymorphic => true
  validates_presence_of     :invoiceable_id, :invoiceable_type
  has_many                  :invoice_line_items, :dependent => :destroy
  has_many_polymorphs       :chargeables, :from => [:products, :services], :through => :invoice_line_items

  # find invoices for completed appointments
  # named_scope :completed,   { :include => :appointment, :conditions => {'appointments.state' => 'completed'} }
  
  # def after_create
  #   # add appointment service as a line item
  #   li = AppointmentInvoiceLineItem.new(:chargeable => appointment.service, :price_in_cents => appointment.service.price_in_cents)
  #   line_items.push(li)
  # end
  
  def total
    invoice_line_items.inject(0) do |sum, item|
      sum += item.price_in_cents
    end
  end
  
  def total_as_money
    Money.new(self.total / 100.0)
  end
  
end