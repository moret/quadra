class TestsController < ApplicationController
  def show
    redis = self.connection
    @ratings = {}
    @ps = {}
    @qs = {}
    @subjects = redis.smembers 'subjects'
    @items = redis.smembers 'items'

    @subjects.each do |subject|
      subject_row = {}
      @ps[subject] = redis.get "ps:#{subject}"
      @items.each do |item|
        ismember = redis.sismember "items:#{item}", subject
        subject_row[item] = ismember ? 1 : 0
      end
      @ratings[subject] = subject_row
    end

    @items.each do |item|
      @qs[item] = redis.get "qs:#{item}"
    end
  end

  def step
    redis = self.connection

    redis.set 'ps:alice', 2

    redirect_to test_path
  end

  def reset
    ratings = {
      :alice => [:one, :two, :five],
      :bob => [:one, :two, :three],
      :carl => [:two, :five, :six]
    }

    redis = self.connection

    subjects = redis.smembers 'subjects'
    subjects.each do |subject|
      redis.del "subjects:#{subject}"
      redis.del "ps:#{subject}"
    end

    items = redis.smembers 'items'
    items.each do |item|
      redis.del "items:#{item}"
      redis.del "qs:#{item}"
    end

    redis.del 'subjects'
    redis.del 'items'

    ratings.each_key do |subject|
      redis.sadd 'subjects', subject
      redis.set "ps:#{subject}", 0.5

      ratings[subject].each do |item|
        redis.sadd 'items', item
        redis.sadd "items:#{item}", subject
      end
    end

    items = redis.smembers 'items'
    items.each do |item|
      redis.set "qs:#{item}", 0.5
    end

    redirect_to test_path
  end

  def connection
    Redis::Namespace.new('quadra')
  end

end
