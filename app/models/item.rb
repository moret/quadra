class Item
  include Mongoid::Document

  field :name, type: String
  field :factors, type: Array

  validates_presence_of :name, :factors
end
