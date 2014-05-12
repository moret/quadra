class PredictedRating

  attr_reader :user, :item, :value

  def initialize user, item, value
    @user = user
    @item = item
    @value = value
  end

  def self.for user, item
    user_factors = UserFactor.where user_id: user.id

    value = 0.0

    user_factors.each do |user_factor|
      item_factor = ItemFactor.where(item_id: item.id, factor_index: user_factor.factor_index).first
      value += user_factor.value * item_factor.value
    end

    PredictedRating.new user, item, value
  end

  def <=> other
    @value <=> other.value
  end
end
