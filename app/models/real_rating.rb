class RealRating
  include Mongoid::Document

  field :user_id, type: BSON::ObjectId
  field :item_id, type: BSON::ObjectId
  field :value, type: Float

  validates_presence_of :user_id, :item_id, :value
  validates_uniqueness_of :item_id, scope: :user_id
end
