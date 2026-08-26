class MapsController < ApplicationController
  before_action :authenticate_user!

  def show
    @graph = GraphMapBuilder.call(viewer: current_user)
  end
end
