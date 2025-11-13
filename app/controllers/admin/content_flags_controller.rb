module Admin
  class ContentFlagsController < ApplicationController
    include Authorizable
    before_action :authenticate_user!
    before_action :authorize_admin!
    before_action :set_content_flag, only: [:approve, :request_review, :edit_content, :destroy_content]
    
    def index
      @flags = ContentFlag.includes(:user, :flaggable, :resolved_by).recent
      
      # Filter by status if specified
      if params[:status].present? && ContentFlag.statuses.keys.include?(params[:status])
        @flags = @flags.where(status: params[:status])
      else
        # Default to pending flags
        @flags = @flags.pending
      end
      
      # Count flags by status for the tabs
      @pending_count = ContentFlag.status_pending.count
      @approved_count = ContentFlag.status_approved.count
      @review_requested_count = ContentFlag.status_review_requested.count
      @edited_count = ContentFlag.status_edited.count
      @deleted_count = ContentFlag.status_deleted.count
    end
    
    def approve
      @flag.update(
        status: 'approved',
        resolved_by: current_user,
        resolved_at: Time.current,
        admin_note: params[:admin_note]
      )
      
      redirect_to admin_content_flags_path, notice: "Content has been approved."
    end
    
    def request_review
      @flag.update(
        status: 'review_requested',
        resolved_by: current_user,
        resolved_at: Time.current,
        admin_note: params[:admin_note]
      )
      
      # TODO: Send notification to content author about review request
      # You could implement email notification here
      
      redirect_to admin_content_flags_path, notice: "Review has been requested from the author."
    end
    
    def edit_content
      # Redirect to the appropriate edit page based on content type
      case @flag.flaggable_type
      when 'Note'
        redirect_to edit_note_path(@flag.flaggable, direct_edit: true)
      when 'Comment'
        redirect_to edit_comment_path(@flag.flaggable, direct_edit: true)
      when 'CrossReference'
        redirect_to admin_content_flags_path, alert: "Cross-references cannot be edited directly. Please delete and recreate if needed."
      end
    end
    
    def destroy_content
      flaggable = @flag.flaggable
      
      # Update flag status
      @flag.update(
        status: 'deleted',
        resolved_by: current_user,
        resolved_at: Time.current,
        admin_note: params[:admin_note]
      )
      
      # Delete the flagged content
      flaggable.destroy
      
      redirect_to admin_content_flags_path, notice: "Content has been deleted."
    end
    
    private
    
    def set_content_flag
      @flag = ContentFlag.find(params[:id])
    end
  end
end

