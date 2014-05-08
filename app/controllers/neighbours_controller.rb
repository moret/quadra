class NeighboursController < ApplicationController
  def show
    if Neighbours.empty?
      Neighbours.create 
      @neighbours = Neighbours.first
    else
      @neighbours = Neighbours.first
      @neighbours.step
    end
  end

  def reset
    Neighbours.destroy_all
    redirect_to neighbours_path
  end
end
