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


  def recommendation_for user_index
    top_item_index = nil
    top_rating = nil
    aproximated_ratings[user_index].each_with_index do |rating, item_index|
      if rating && !original_ratings[user_index][item_index]
        if top_rating
          if rating > top_rating
            top_rating = rating
            top_item_index = item_index
          end
        else
          top_rating = rating
          top_item_index = item_index
        end
      end
    end

    if top_item_index
      items[top_item_index]
    else
      '?'
    end
  end