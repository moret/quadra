class NeighboursController < ApplicationController
  def show
    if Neighbours.empty?
      redirect_to reset_neighbours_path
    else
      @neighbours = Neighbours.first
    end
  end

  def step
    neighbours = Neighbours.first
    2.times do
      neighbours.step
    end

    while neighbours.rmses[-2] > neighbours.rmses[-1] do
      neighbours.step
    end

    redirect_to neighbours_path
  end

  def reset
    Neighbours.its_time!

    redirect_to neighbours_path
  end
end
