class NeighboursController < ApplicationController
  def show
    if Neighbours.empty?
      redirect_to reset_neighbours_path
    else
      @neighbours = Neighbours.first
    end
  end

  def step
    Neighbours.first.step

    redirect_to neighbours_path
  end

  def reset
    Item.destroy_all
    ItemFactor.destroy_all
    Neighbours.destroy_all
    PredictedRating.destroy_all
    RealRating.destroy_all
    User.destroy_all
    UserFactor.destroy_all

    Neighbours.its_time!

    redirect_to neighbours_path
  end
end
