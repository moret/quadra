class User
  include Mongoid::Document

  field :name, type: String
  field :recommended_items_ids, type: Array

  validates_presence_of :name

  def top_predicted_items how_many=5
    if recommended_items_ids
      Item.find recommended_items_ids[0..how_many-1]
    else
      []
    end
  end
end
