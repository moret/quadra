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
  MAX_EVAL = 5
  INITIAL_FACTORS_RANGE = (MAX_EVAL.to_f/2/FACTORS_SIZE/2)..(MAX_EVAL.to_f/2/FACTORS_SIZE)
  INITIAL_RATINGS_RANGE = 1..MAX_EVAL
  RECOMMENDATIONS_LIMIT = 10
  MINIMUM_STEPS = 5
  ERROR_VARIANCE_STOP = 0.0001

  field :rmses, type: Array, default: []
  field :untrained_rmses, type: Array, default: []

  def self.clear_the_house
    puts 'clearing...'

    User.destroy_all
    Item.destroy_all
    Neighbours.destroy_all

    Neighbours.create!
  end

  def self.random_array size, range
    Array.new(FACTORS_SIZE) { Random.rand INITIAL_FACTORS_RANGE }
  end

  def self.load_from_file filename='ratings.json'
    clear_the_house

    puts 'loading...'

    raw_ratings = JSON.load File.read filename
    raw_ratings = Hash[raw_ratings.to_a[0..200]]

    puts "found #{raw_ratings.count} users"

    items_map = {}
    raw_ratings.values.each do |items_ratings|
      items_ratings.keys.each do |item_external_id|
        items_map[item_external_id] = nil
      end
    end

    puts "found #{items_map.count} items"

    count = 0
    items_map.keys.each do |item_external_id|
      factors = random_array FACTORS_SIZE, INITIAL_FACTORS_RANGE
      item = Item.create! name: item_external_id, factors: factors
      items_map[item_external_id] = item.id

      count += 1
      puts "new items so far: #{count}" if count % 1000 == 0
    end

    count = 0
    raw_ratings.each do |user_external_id, items_ratings|
      ratings = {}
      untrained_ratings = {}
      items_ratings.each_slice(2) do |rating, untrained_rating|
        if rating
          item_external_id, item_rating = rating
          ratings[items_map[item_external_id]] = item_rating
        end
        if untrained_rating
          item_external_id, item_rating = untrained_rating
          untrained_ratings[items_map[item_external_id]] = item_rating
        end
      end

      factors = random_array FACTORS_SIZE, INITIAL_FACTORS_RANGE
      User.create! name: user_external_id, factors: factors, ratings: ratings, untrained_ratings: untrained_ratings

      count += 1
      puts "new users so far: #{count}" if count % 1000 == 0
    end

    puts 'done'
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
      Item.all.each do |item|
        if Random.rand(SPARSE_RANGE) == 0
          user.ratings[item.id] = Random.rand INITIAL_RATINGS_RANGE
        else
          if Random.rand(SPARSE_RANGE) == 0
            user.untrained_ratings[item.id] = Random.rand INITIAL_RATINGS_RANGE
          end
        end
      end
      user.save!
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
    puts 'caching items...'
    items_cache = {}
    Item.all.each do |item|
      items_cache[item.id.to_s] = item
    end

    puts 'calculating factors...'
    user_count = 0
    User.all.each do |user|
      user_factors = user.factors

      user.ratings.each do |item_id, real_rating|
        item = items_cache[item_id]
        item_factors = item.factors
        quad_error = (real_rating - PredictedRating.for(user, item).value) ** 2
        root_error = Math.sqrt quad_error

        user_factors.each_with_index do |user_factor, factor_index|
          item_factor = item.factors[factor_index]
          user_factors[factor_index] = user_factor + 2 * ALPHA * root_error * item_factor
          item.factors[factor_index] = item_factor + 2 * ALPHA * root_error * user_factor
        end
      end

      user.update_attributes! factors: user_factors

      user_count += 1
      puts "calculated factors for #{user_count} users so far" if user_count % 1000 == 0
    end

    puts 'saving updated items...'
    items_cache.values.each do |item|
      item.save!
    end

    quad_sum_error = 0.0
    total_ratings = 0

    untrained_quad_sum_error = 0.0
    untrained_total_ratings = 0

    puts 'updating recommendations...'
    user_count = 0
    User.all.each do |user|
      recommendations = RecommendationsSet.new RECOMMENDATIONS_LIMIT

      items_cache.values.each do |item|
        predicted_rating = PredictedRating.for user, item
        trained_rating = user.rating_for item
        untrained_rating = user.untrained_rating_for item

        if trained_rating
          quad_sum_error += (trained_rating - predicted_rating.value) ** 2
          total_ratings += 1
        elsif untrained_rating
          untrained_quad_sum_error += (untrained_rating - predicted_rating.value) ** 2
          untrained_total_ratings += 1
        else
          recommendations.push predicted_rating
        end
      end

      user.update_attributes! recommended_items_ids: recommendations.ids

      user_count += 1
      puts "updated #{user_count} users so far" if user_count % 1000 == 0
    end

    rmses << Math.sqrt(quad_sum_error / total_ratings)
    untrained_rmses << Math.sqrt(untrained_quad_sum_error / untrained_total_ratings)
    save!
  end

  def factors_size
    FACTORS_SIZE
  end
end
