class TestsController < ApplicationController
  def show
    redis = self.connection
    @ratings = {}
    @recommendations = {}
    @converged = {}
    @ps = {}
    @qs = {}
    @quad_error_sums = redis.lrange 'quad_error_sums', 0, -1
    @steps = redis.get('steps').to_i
    @history = redis.get('history').to_i
    @iter = @steps % @history
    @stahp = @quad_error_sums[-1] > @quad_error_sums[-2]
    @subjects = redis.smembers 'subjects'
    @items = redis.smembers 'items'

    @subjects.each do |subject|
      ratings_row = {}
      p = redis.get("ps:#{subject}").to_f
      @ps[subject] = p
      @items.each do |item|
        q = redis.get("qs:#{item}").to_f
        @qs[item] = q
        ratings_row[item] = redis.sismember "items:#{item}", subject
      end
      recommendations = redis.zrevrange("recommendations:#{@iter}:#{subject}", 0, 2).join(',')
      converged = true
      @history.times do |h|
        converged = recommendations == redis.zrevrange("recommendations:#{h}:#{subject}", 0, 2).join(',') if converged
      end

      @ratings[subject] = ratings_row
      @recommendations[subject] = recommendations
      @converged[subject] = converged
    end
  end

  def step
    alpha = 0.01

    redis = self.connection
    redis.incr 'steps'

    subjects = redis.smembers 'subjects'
    items = redis.smembers 'items'
    iter = redis.get('steps').to_i % redis.get('history').to_i

    subjects.each do |subject|
      items.each do |item|
        p = redis.get("ps:#{subject}").to_f
        q = redis.get("qs:#{item}").to_f

        recommendation = p * q
        rated = redis.sismember "items:#{item}", subject
        rating = rated ? 1 : 0
        # if rated
          quad_error = (rating - recommendation) ** 2
          root_error = Math.sqrt quad_error

          new_p = p + 2 * alpha * root_error * q
          new_q = q + 2 * alpha * root_error * p

          redis.set "ps:#{subject}", new_p
          redis.set "qs:#{item}", new_q
        # end
      end
    end

    quad_error_sum = 0.0

    subjects.each do |subject|
      redis.del "recommendations:#{subject}"
      p = redis.get("ps:#{subject}").to_f
      items.each do |item|
        q = redis.get("qs:#{item}").to_f
        recommendation = p * q
        rated = redis.sismember "items:#{item}", subject
        rating = rated ? 1 : 0
        redis.zadd "recommendations:#{iter}:#{subject}", recommendation, item unless rated
        quad_error_sum += (rating - recommendation) ** 2
      end
    end

    redis.lpop 'quad_error_sums'
    redis.rpush 'quad_error_sums', quad_error_sum

    redirect_to test_path
  end

  def random_ratings
    ratings = {}
    items = Array.new(25) {|i| i.to_s}
    subjects = [:alice, :bob, :carl, :dan, :fred]
    subjects.each do |subject|
      ratings[subject] = []
      3.times do |i|
        ratings[subject] << items[rand(items.size)]
      end
    end
    ratings
  end

  def reset
    start = 0.1
    history = 3
    ratings = random_ratings

    redis = self.connection

    subjects = redis.smembers 'subjects'
    subjects.each do |subject|
      redis.del "subjects:#{subject}"
      redis.del "ps:#{subject}"
      history.times do |h|
        redis.del "recommendations:#{h}:#{subject}"
      end
    end

    items = redis.smembers 'items'
    items.each do |item|
      redis.del "items:#{item}"
      redis.del "qs:#{item}"
    end

    redis.del 'subjects'
    redis.del 'items'
    redis.del 'quad_error_sums'

    ratings.each_key do |subject|
      redis.sadd 'subjects', subject
      redis.set "ps:#{subject}", start

      ratings[subject].each do |item|
        redis.sadd 'items', item
        redis.sadd "items:#{item}", subject
      end
    end

    items = redis.smembers 'items'
    items.each do |item|
      redis.set "qs:#{item}", start
    end

    history.times do |h|
      redis.rpush 'quad_error_sums', items.size * subjects.size
    end

    redis.set 'steps', 0
    redis.set 'history', history

    redirect_to test_path
  end

  def connection
    Redis::Namespace.new('quadra')
  end

end
