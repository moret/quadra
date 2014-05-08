class Neighbours
  include Mongoid::Document

  USERS_SIZE = 4
  ITEMS_SIZE = 12
  FACTORS_SIZE = 3
  INITIAL_FACTOR_VALUE = 0.1

  field :users, type: Array, default: ->{ JSON.load Net::HTTP.get 'namey.muffinlabs.com', "/name.json?count=#{USERS_SIZE}&with_surname=false&frequency=all" }
  field :items, type: Array, default: ->{ Array.new(ITEMS_SIZE) {|i| i.humanize} }

  field :p_matrix, type: Array, default: ->{ Array.new(USERS_SIZE) {|i| Array.new(FACTORS_SIZE) {|j| INITIAL_FACTOR_VALUE}} }
  field :q_matrix, type: Array, default: ->{ Array.new(FACTORS_SIZE) {|i| Array.new(ITEMS_SIZE) {|j| INITIAL_FACTOR_VALUE}} }

  field :ratings, type: Array, default: ->{ Array.new(USERS_SIZE) {|u| Array.new(ITEMS_SIZE) {|i| Random.rand(0..2) == 0 ? Random.rand(1..5) : nil }} }

  field :quad_sum_errors, type: Array, default: []

  def step
    quad_sum_errors << Time.now.to_i
    save!
  end
end
