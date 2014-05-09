class ItemFactor
  include Mongoid::Document

  field :item_id, type: BSON::ObjectId
  field :factor_index, type: Integer
  field :value, type: Float

  validates_presence_of :item_id, :factor_index, :value
  validates_uniqueness_of :factor_index, scope: :item_id
end
