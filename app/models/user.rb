class User
  include Mongoid::Document

  field :name, type: String

  validates_presence_of :name

  def top_predicted_item
    predicted_ratings = PredictedRating.where user_id: id
    predicted_ratings.order_by :value
    if predicted_ratings.first
      Item.find predicted_ratings.first.item_id
    end
  end
end
