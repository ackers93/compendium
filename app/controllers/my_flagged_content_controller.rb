class MyFlaggedContentController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Get all flags for content created by the current user
    @flags = ContentFlag.includes(:flaggable, :user, :resolved_by)
                        .where(flaggable: current_user_content)
                        .recent
    
    # Filter by status if specified
    if params[:status].present? && ContentFlag.statuses.keys.include?(params[:status])
      @flags = @flags.where(status: params[:status])
    else
      # Default to showing review_requested flags
      @flags = @flags.status_review_requested
    end
    
    # Count flags by status for the current user's content
    all_user_flags = ContentFlag.where(flaggable: current_user_content)
    @pending_count = all_user_flags.status_pending.count
    @review_requested_count = all_user_flags.status_review_requested.count
    @approved_count = all_user_flags.status_approved.count
    @edited_count = all_user_flags.status_edited.count
    @deleted_count = all_user_flags.status_deleted.count
  end
  
  private
  
  def current_user_content
    # Get all content created by current user across all flaggable types
    notes = current_user.notes
    comments = current_user.comments
    cross_refs = current_user.cross_references
    
    notes + comments + cross_refs
  end
end

