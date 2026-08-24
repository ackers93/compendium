class BulkUploadHubController < ApplicationController
  include Authorizable
  include BulkUploadHubRendering

  before_action :authenticate_user!
  before_action :authorize_create!

  def show
    @tab = TABS.include?(params[:tab]) ? params[:tab] : "comments"
    assign_bulk_hub_defaults(active_tab: @tab)
  end
end
