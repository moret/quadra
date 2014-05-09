class Neighbours
  include Mongoid::Document

  USERS_SIZE = 10
  ITEMS_SIZE = 20
  FACTORS_SIZE = 3
  ALPHA = 0.01

  field :quad_sum_errors, type: Array, default: []

  def self.its_time!
    Neighbours.create!

    user_names = JSON.load Net::HTTP.get 'namey.muffinlabs.com', "/name.json?count=#{USERS_SIZE}&with_surname=false&frequency=all"
    user_names.each do |user_name|
      User.create! name: user_name
    end

    1.upto(ITEMS_SIZE) do |item_serial|
      Item.create! name: item_serial.humanize
    end

    1.upto(FACTORS_SIZE) do |factor_index|
      User.all.each do |user|
        UserFactor.create! user_id: user.id, factor_index: factor_index, value: Random.rand(0.1..0.3)
      end

      Item.all.each do |item|
        ItemFactor.create! item_id: item.id, factor_index: factor_index, value: Random.rand(0.1..0.3)
      end
    end

    User.all.each do |user|
      Item.all.each do |item|
        luck = Random.rand(0..2)
        if luck == 0
          RealRating.create! user_id: user.id, item_id: item.id, value: Random.rand(1..5)
        end
      end
    end
  end

  def step
    User.all.each do |user|
      Item.all.each do |item|
        user_factors = UserFactor.where user_id: user.id

        aproximated_rating_value = 0.0

        user_factors.each do |user_factor|
          item_factor = ItemFactor.where(item_id: item.id, factor_index: user_factor.factor_index).first
          aproximated_rating_value += user_factor.value * item_factor.value
        end

        real_rating = RealRating.where(user_id: user.id, item_id: item.id).first
        if real_rating
          quad_error = (real_rating.value - aproximated_rating_value) ** 2
          root_error = Math.sqrt quad_error

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

    User.all.each do |user|
      Item.all.each do |item|
        user_factors = UserFactor.where user_id: user.id

        aproximated_rating_value = 0.0

        user_factors.each do |user_factor|
          item_factor = ItemFactor.where(item_id: item.id, factor_index: user_factor.factor_index).first
          aproximated_rating_value += user_factor.value * item_factor.value
        end

        real_rating = RealRating.where(user_id: user.id, item_id: item.id).first

        if real_rating
          quad_sum_error += (real_rating.value - aproximated_rating_value) ** 2
        else
          predicted_rating = PredictedRating.find_or_initialize_by user_id: user.id, item_id: item.id
          predicted_rating.value = aproximated_rating_value
          predicted_rating.save!
        end
      end
    end

    quad_sum_errors << quad_sum_error
    save!
  end

  def factors_size
    FACTORS_SIZE
  end
end
