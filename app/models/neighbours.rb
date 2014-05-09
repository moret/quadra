class Neighbours
  include Mongoid::Document

  USERS_SIZE = 10
  ITEMS_SIZE = 20
  FACTORS_SIZE = 3
  ALPHA = 0.01

  field :users, type: Array, default: ->{ JSON.load Net::HTTP.get 'namey.muffinlabs.com', "/name.json?count=#{USERS_SIZE}&with_surname=false&frequency=all" }
  field :items, type: Array, default: ->{ Array.new(ITEMS_SIZE) {|i| i.humanize} }

  field :p_matrix, type: Array, default: ->{ Array.new(USERS_SIZE) {|i| Array.new(FACTORS_SIZE) {|j| Random.rand 0.1..0.3}} }
  field :q_matrix, type: Array, default: ->{ Array.new(ITEMS_SIZE) {|i| Array.new(FACTORS_SIZE) {|j| Random.rand 0.1..0.3}} }

  field :original_ratings, type: Array, default: ->{ Array.new(USERS_SIZE) {|u| Array.new(ITEMS_SIZE) {|i| Random.rand(0..2) == 0 ? Random.rand(1..5) : nil }} }
  field :aproximated_ratings, type: Array, default: ->{ original_ratings }

  field :recommendations, type: Array, default: ->{ Array.new(USERS_SIZE) {|u| []} }
  field :quad_sum_errors, type: Array, default: []

  def step
    users.each_with_index do |user, user_index|
      items.each_with_index do |item, item_index|
        p_factors = p_matrix[user_index]
        q_factors = q_matrix[item_index]

        aproximated_rating = 0.0
        p_factors.each_with_index do |p_factor, i|
          aproximated_rating += p_factor * q_factors[i]
        end

        original_rating = original_ratings[user_index][item_index]
        if original_rating
          quad_error = (original_rating - aproximated_rating) ** 2
          root_error = Math.sqrt quad_error

          p_factors.each_with_index do |p_factor, i|
            q_factor = q_factors[i]

            p_factors[i] = p_factor + 2 * ALPHA * root_error * q_factor
            q_factors[i] = q_factor + 2 * ALPHA * root_error * p_factor
          end
        end
      end
    end

    quad_sum_error = 0.0

    users.each_with_index do |user, user_index|
      items.each_with_index do |item, item_index|
        p_factors = p_matrix[user_index]
        q_factors = q_matrix[item_index]

        aproximated_rating = 0.0
        p_factors.each_with_index do |p_factor, i|
          aproximated_rating += p_factor * q_factors[i]
        end

        original_rating = original_ratings[user_index][item_index]
        if original_rating
          quad_sum_error += (original_rating - aproximated_rating) ** 2
        else
          aproximated_ratings[user_index][item_index] = aproximated_rating
        end
      end
    end

    quad_sum_errors << quad_sum_error
    save!
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

  def factors_size
    FACTORS_SIZE
  end
end
