class Quote::SubmissionSerializer < ActiveModel::Serializer
  attributes :id, :shipment_items_count, :status

  has_one :contact
  has_one :delivery_address
  has_one :pickup_address
  has_many :shipment_items
end
