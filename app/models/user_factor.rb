class UserFactor
  include Mongoid::Document

  field :user_id, type: BSON::ObjectId
  field :factor_index, type: Integer
  field :value, type: Float

  validates_presence_of :user_id, :factor_index, :value
  validates_uniqueness_of :factor_index, scope: :user_id
end
