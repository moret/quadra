class User
  include Mongoid::Document

  field :name, type: String
  field :factors, type: Array
  field :ratings, type: Hash, default: {}
  field :untrained_ratings, type: Hash, default: {}
  field :recommended_items_ids, type: Array, default: []

  validates_presence_of :name, :factors

  def top_predicted_items how_many=5
    if recommended_items_ids
      Item.find recommended_items_ids[0..how_many-1]
    else
      []
    end
  end

  def rating_for item
    ratings[item.id.to_s]
  end

  def untrained_rating_for item
    untrained_ratings[item.id.to_s]
  end
end
