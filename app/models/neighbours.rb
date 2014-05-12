class Neighbours
  include Mongoid::Document

  USERS_SIZE = 8
  ITEMS_SIZE = 18
  FACTORS_SIZE = 3
  ALPHA = 0.001
  SPARSE_RANGE = 0..10
  INITIAL_FACTORS_RANGE = 0.01..0.1
  INITIAL_RATINGS_RANGE = 0..5
  RECOMMENDATIONS_COUNT = 10

  field :rmses, type: Array, default: []

  def self.its_time!
    Item.destroy_all
    ItemFactor.destroy_all
    Neighbours.destroy_all
    RealRating.destroy_all
    User.destroy_all
    UserFactor.destroy_all

    Neighbours.create!

    user_names = JSON.load Net::HTTP.get 'namey.muffinlabs.com', "/name.json?count=#{USERS_SIZE}&with_surname=false&frequency=all"
    user_names.each do |user_name|
      User.create! name: user_name
    end

    # 1.upto(USERS_SIZE) do |user_serial|
    #   User.create! name: user_serial.humanize
    # end

    1.upto(ITEMS_SIZE) do |item_serial|
      Item.create! name: item_serial.humanize
    end

    1.upto(FACTORS_SIZE) do |factor_index|
      User.all.each do |user|
        UserFactor.create! user_id: user.id, factor_index: factor_index, value: Random.rand(INITIAL_FACTORS_RANGE)
      end

      Item.all.each do |item|
        ItemFactor.create! item_id: item.id, factor_index: factor_index, value: Random.rand(INITIAL_FACTORS_RANGE)
      end
    end

    User.all.each do |user|
      Item.all.each do |item|
        luck = Random.rand SPARSE_RANGE
        if luck == 0
          RealRating.create! user_id: user.id, item_id: item.id, value: Random.rand(INITIAL_RATINGS_RANGE)
        end
      end
    end
  end

  def step
    User.all.each do |user|
      Item.all.each do |item|
        aproximated_rating_value = PredictedRating.for(user, item).value
        real_rating = RealRating.where(user_id: user.id, item_id: item.id).first
        if real_rating
          quad_error = (real_rating.value - aproximated_rating_value) ** 2
          root_error = Math.sqrt quad_error

          user_factors = UserFactor.where user_id: user.id
          user_factors.each do |user_factor|
            item_factor = ItemFactor.where(item_id: item.id, factor_index: user_factor.factor_index).first

            user_factor_value = user_factor.value + 2 * ALPHA * root_error * item_factor.value
            item_factor_value = item_factor.value + 2 * ALPHA * root_error * user_factor.value

            user_factor.update_attributes! value: user_factor_value
            item_factor.update_attributes! value: item_factor_value
          end
        end
      end
    end

    quad_sum_error = 0.0
    total_ratings = 0
    predicted_ratings = {}

    User.all.each do |user|
      recommendations = SortedSet.new
      unless predicted_ratings[user.id]
        predicted_ratings[user.id] = {}
      end

      Item.all.each do |item|
        predicted_rating = PredictedRating.for user, item
        real_rating = RealRating.where(user_id: user.id, item_id: item.id).first
        if real_rating
          quad_sum_error += (real_rating.value - predicted_rating.value) ** 2
          total_ratings += 1
        else
          predicted_ratings[user.id][item.id] = predicted_rating.value
          recommendations.add predicted_rating
          if recommendations.count > RECOMMENDATIONS_COUNT
            recommendations.delete recommendations.to_a.first
          end
        end
      end
      user.update_attributes! recommended_items_ids: recommendations.to_a.collect{|r| r.item.id}.reverse
    end

    rmses << Math.sqrt(quad_sum_error / total_ratings)
    save!

    predicted_ratings
  end

  def factors_size
    FACTORS_SIZE
  end
end
