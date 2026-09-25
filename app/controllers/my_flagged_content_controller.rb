class MyFlaggedContentController < ApplicationController
  before_action :authenticate_user!
  
  def index
    all_user_flags = ContentFlag.where(content_author_id: current_user.id)

    @flags = all_user_flags.includes(:flaggable, :user, :resolved_by).recent

    # Filter by status if specified
    if params[:status].present? && ContentFlag.statuses.keys.include?(params[:status])
      @flags = @flags.where(status: params[:status])
    else
      # Default to showing review_requested flags
      @flags = @flags.status_review_requested
    end

    # Count flags by status for the current user's content
    @pending_count = all_user_flags.status_pending.count
    @review_requested_count = all_user_flags.status_review_requested.count
    @approved_count = all_user_flags.status_approved.count
    @edited_count = all_user_flags.status_edited.count
    @deleted_count = all_user_flags.status_deleted.count
  end
end
