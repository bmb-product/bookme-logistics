class Quote::Submission < ApplicationRecord

  has_one :pickup_address, class_name: 'Quote::PickupAddress', dependent: :destroy
  has_one :delivery_address, class_name: 'Quote::DeliveryAddress', dependent: :destroy
  has_one :contact, class_name: 'Quote::Contact', dependent: :destroy

  has_many :shipment_items, class_name: 'Quote::ShipmentItem', dependent: :destroy
  enum status: [:open, :assigned, :completed, :confirmed, :closed ]

  accepts_nested_attributes_for :pickup_address, allow_destroy: true
  accepts_nested_attributes_for :delivery_address, allow_destroy: true
  accepts_nested_attributes_for :contact, allow_destroy: true
  accepts_nested_attributes_for :shipment_items, allow_destroy: true

  def nested_errors
    errors = {}
    errors[:contact] = self.contact.errors if !self.contact.valid?
    errors[:pickup_address] = self.pickup_address.errors if !self.pickup_address.valid?
    errors[:delivery_address] = self.delivery_address.errors if !self.delivery_address.valid?

    return errors if self.shipment_items.select {|item| !item.valid?}.empty?

    self.shipment_items.each_with_index do |shipment_item, index|
      errors[:shipment_items] ||= {}
      errors[:shipment_items][index] = shipment_item.errors if !shipment_item.valid?
    end
    errors
  end
  
end
