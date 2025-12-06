module Admin
  class ReviewsController < ApplicationController
    include Authorizable
    before_action :authenticate_user!
    before_action :authorize_admin!
    
    def index
      # Filter by type if specified
      if params[:type] == 'comments'
        @comments = Comment.includes(:user, :commentable).order(created_at: :desc)
        @cross_references = []
      elsif params[:type] == 'cross_references'
        @cross_references = CrossReference.includes(:user, :source_verse, :target_verse).order(created_at: :desc)
        @comments = []
      else
        # Show both, ordered by most recent
        @comments = Comment.includes(:user, :commentable).order(created_at: :desc)
        @cross_references = CrossReference.includes(:user, :source_verse, :target_verse).order(created_at: :desc)
      end
      
      # Get counts for stats
      @comments_count = Comment.count
      @cross_references_count = CrossReference.count
    end
    
    def destroy_comment
      @comment = Comment.find(params[:id])
      @comment.destroy
      redirect_to admin_reviews_path(type: params[:type] || 'all'), notice: "Comment has been deleted."
    end
    
    def destroy_cross_reference
      @cross_reference = CrossReference.find(params[:id])
      @cross_reference.destroy
      redirect_to admin_reviews_path(type: params[:type] || 'all'), notice: "Cross-reference has been deleted."
    end
  end
end
