class NeighboursController < ApplicationController
  def show
    if Neighbours.empty?
      redirect_to reset_neighbours_path
    else
      @neighbours = Neighbours.first
    end
  end

  def walk
    Neighbours.first.walk
    redirect_to neighbours_path
  end

  def step
    Neighbours.first.step
    redirect_to neighbours_path
  end

  def reset
    Neighbours.its_time!
    redirect_to neighbours_path
  end
end
