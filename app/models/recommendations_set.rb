class RecommendationsSet
  def initialize limit
    @limit = limit
    @sorted_set = SortedSet.new
  end

  def push predicted_rating
    @sorted_set.add predicted_rating

    if @sorted_set.count > @limit
      @sorted_set.delete @sorted_set.to_a.first
    end
  end

  def ids
    @sorted_set.to_a.collect{|r| r.item.id}.reverse
  end
end
