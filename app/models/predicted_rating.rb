class PredictedRating

  attr_reader :user, :item, :value

  def initialize user, item, value
    @user = user
    @item = item
    @value = value
  end

  def self.for user, item
    value = 0.0

    user.factors.each_with_index do |user_factor, factor_index|
      item_factor = item.factors[factor_index]
      value += user_factor * item_factor
    end

    PredictedRating.new user, item, value
  end

  def <=> other
    @value <=> other.value
  end
end
