class Neighbours
  include Mongoid::Document

  # USERS_SIZE = 300
  # ITEMS_SIZE = 1000
  # FACTORS_SIZE = 5
  # SPARSE_RANGE = 0..500

  USERS_SIZE = 8
  ITEMS_SIZE = 18
  FACTORS_SIZE = 3
  SPARSE_RANGE = 0..10

  ALPHA = 0.001
  INITIAL_FACTORS_RANGE = 0.1..0.3
  INITIAL_RATINGS_RANGE = 1..5
  RECOMMENDATIONS_LIMIT = 10
  MINIMUM_STEPS = 5
  ERROR_VARIANCE_STOP = 0.0001

  field :rmses, type: Array, default: []

  def self.clear_the_house
    User.destroy_all
    Item.destroy_all
    Neighbours.destroy_all

    Neighbours.create!
  end

  def self.its_time!
    clear_the_house

    1.upto(USERS_SIZE) do |user_serial|
      factors = Array.new(FACTORS_SIZE) do
        Random.rand INITIAL_FACTORS_RANGE
      end

      User.create! name: user_serial.humanize, factors: factors
    end

    1.upto(ITEMS_SIZE) do |item_serial|
      factors = Array.new(FACTORS_SIZE) do
        Random.rand INITIAL_FACTORS_RANGE
      end

      Item.create! name: item_serial.humanize, factors: factors
    end

    User.all.each do |user|
      ratings = user.ratings
      Item.all.each do |item|
        luck = Random.rand SPARSE_RANGE
        if luck == 0
          ratings[item.id] = Random.rand INITIAL_RATINGS_RANGE
        end
      end
      user.update_attributes! ratings: ratings
    end
  end

  def walk
    (MINIMUM_STEPS - rmses.count).times do
      step
    end

    while (rmses[-2] - rmses[-1] > ERROR_VARIANCE_STOP) do
      step
    end
  end

  def step
    User.all.each do |user|
      user_factors = user.factors

      Item.all.each do |item|
        real_rating = user.rating_for item

        if real_rating
          item_factors = item.factors
          quad_error = (real_rating - PredictedRating.for(user, item).value) ** 2
          root_error = Math.sqrt quad_error

          user_factors.each_with_index do |user_factor, factor_index|
            item_factor = item_factors[factor_index]
            user_factors[factor_index] = user_factor + 2 * ALPHA * root_error * item_factor
            item_factors[factor_index] = item_factor + 2 * ALPHA * root_error * user_factor
          end

          item.update_attributes! factors: item_factors
        end
      end

      user.update_attributes! factors: user_factors
    end

    quad_sum_error = 0.0
    total_ratings = 0

    User.all.each do |user|
      recommendations = RecommendationsSet.new RECOMMENDATIONS_LIMIT

      Item.all.each do |item|
        predicted_rating = PredictedRating.for user, item
        real_rating = user.rating_for item

        if real_rating
          quad_sum_error += (real_rating - predicted_rating.value) ** 2
          total_ratings += 1
        else
          recommendations.push predicted_rating
        end
      end

      user.update_attributes! recommended_items_ids: recommendations.ids
    end

    rmses << Math.sqrt(quad_sum_error / total_ratings)
    save!
  end

  def factors_size
    FACTORS_SIZE
  end
end
