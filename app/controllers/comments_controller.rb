class CommentsController < ApplicationController
  include ActionView::RecordIdentifier
  include Authorizable
  
  before_action :authenticate_user!
  before_action :set_comment, only: %i[ show edit update destroy ]
  before_action :ensure_frame_response, only: [:new, :edit]
  before_action :set_commentable, only: [:new, :create]
  before_action :authorize_create!, only: %i[ new create ]
  before_action -> { authorize_edit!(@comment) }, only: %i[ edit update ]
  before_action -> { authorize_delete!(@comment) }, only: %i[ destroy ]

  def index
    @comments = Comment.all
  end

  def show
    @comment = Comment.find(params[:id])
    @commentable = @comment.commentable
  end

  def new
    @comment = @commentable.comments.build
  end

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.turbo_stream { 
          if @commentable.is_a?(CrossReference)

            render turbo_stream: [
              turbo_stream.replace("cross-references", 
                partial: "cross_references/cross_references_list", 
                locals: { cross_references: @commentable.source_verse.ordered_cross_references, verse: @commentable.source_verse }
              )
            ]
          elsif @commentable.comments.count == 1
            # First comment - replace the "no comments" message with the comment
            render turbo_stream: [
              turbo_stream.replace("comments", partial: "comments/comments_list", locals: { commentable: @commentable }),
              turbo_stream.replace("comment-form", partial: "comments/form", locals: { comment: @commentable.comments.build }),
              turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @commentable })
            ]
          else
            # Additional comments - append to existing list
            render turbo_stream: [
              turbo_stream.append("comments", partial: "comments/comment", locals: { comment: @comment }),
              turbo_stream.replace("comment-form", partial: "comments/form", locals: { comment: @commentable.comments.build }),
              turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @commentable })
            ]
          end
        }
        format.html { 
          if @commentable.is_a?(CrossReference)
            # Cross-references use Turbo Streams, so this shouldn't be reached
            redirect_to root_path
          else
            redirect_to @commentable, notice: "Comment was successfully created."
          end
        }
        format.json { render json: { id: @comment.id, content: @comment.content }, status: :created, location: @comment }
      else
        format.turbo_stream { 
          if @commentable.is_a?(CrossReference)
            # Re-render the cross-reference comment modal with errors
            render turbo_stream: turbo_stream.replace("modal", 
              partial: "cross_references/new_comment", locals: { cross_ref: @commentable, comment: @comment }
            )
          else
            # Just re-render the form with errors
            render turbo_stream: [
              turbo_stream.replace("comment-form", 
                partial: "comments/form", locals: { comment: @comment }
              )
            ]
          end
        }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @comment = Comment.find(params[:id])
    @commentable = @comment.commentable
  end

  def update
    respond_to do |format|
      if @comment.update(comment_params)
        notice_message = if @comment.flagged_content_was_updated
          "Comment was successfully updated and has been submitted back to admins for review. Thank you for addressing the feedback!"
        else
          "Comment was successfully updated."
        end
        
        format.turbo_stream { 
          # Normal modal updates - direct_edit cases will use HTML format
          if @comment.commentable.is_a?(CrossReference)
            # Handle cross-reference comment updates - replace the entire cross-references list
            render turbo_stream: [
              turbo_stream.replace("modal", ""),
              turbo_stream.replace("cross-references", 
                partial: "cross_references/cross_references_list", 
                locals: { cross_references: @comment.commentable.source_verse.ordered_cross_references, verse: @comment.commentable.source_verse }
              )
            ]
          else
            render turbo_stream: [
              turbo_stream.replace("modal", ""),
              turbo_stream.replace(dom_id(@comment), partial: "comments/comment", locals: { comment: @comment })
            ]
          end
        }
        format.html { 
          # If editing from flagged content review, redirect appropriately
          if params[:direct_edit] && @comment.flagged_content_was_updated
            redirect_to my_flagged_content_path, notice: notice_message
          elsif @comment.commentable.is_a?(BibleVerse)
            redirect_to bible_verse_show_path(book: @comment.commentable.book, chapter: @comment.commentable.chapter, verse: @comment.commentable.verse), notice: notice_message
          else
            redirect_to @comment.commentable, notice: notice_message
          end
        }
        format.json { render json: { id: @comment.id, content: @comment.content }, status: :ok, location: @comment }
      else
        format.turbo_stream { 
          # Re-render the edit modal with errors
          render turbo_stream: [
            turbo_stream.replace("modal", 
              partial: "comments/edit", locals: { comment: @comment }
            )
          ]
        }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @commentable = @comment.commentable
    @comment.destroy
    
    respond_to do |format|
      format.turbo_stream { 
        if @commentable.is_a?(CrossReference)
          # Handle cross-reference comment deletion
          if @commentable.comments.any?
            # Still have comments - update the comments summary
            render turbo_stream: [
              turbo_stream.replace("comments-summary-#{@commentable.id}", 
                partial: "cross_references/comments_summary", locals: { cross_ref: @commentable }
              )
            ]
          else
            # No more comments - show the "no comments" message
            render turbo_stream: [
              turbo_stream.replace("comments-summary-#{@commentable.id}", 
                partial: "cross_references/comments_summary", locals: { cross_ref: @commentable }
              )
            ]
          end
        elsif @commentable.comments.any?
          # Still have comments - update the list and count
          render turbo_stream: [
            turbo_stream.replace("comments", partial: "comments/comments_list", locals: { commentable: @commentable }),
            turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @commentable })
          ]
        else
          # No more comments - show the "no comments" message and update count
          render turbo_stream: [
            turbo_stream.replace("comments", partial: "comments/comments_list", locals: { commentable: @commentable }),
            turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @commentable })
          ]
        end
      }
      format.html { 
        if @commentable.is_a?(BibleVerse)
          redirect_to bible_verse_show_path(book: @commentable.book, chapter: @commentable.chapter, verse: @commentable.verse), notice: "Comment was successfully deleted."
        else
          redirect_to @commentable, notice: "Comment was successfully deleted."
        end
      }
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def set_commentable
    @commentable = if params[:note_id]
                     Note.find(params[:note_id])
                   elsif params[:book] && params[:chapter] && params[:verse]
                     BibleVerse.find_by(book: params[:book], chapter: params[:chapter].to_i, verse: params[:verse].to_i)
                   elsif params[:bible_verse_id]
                     BibleVerse.find(params[:bible_verse_id])
                   elsif params[:cross_reference_id]
                     CrossReference.find(params[:cross_reference_id])
                   elsif params[:id] && request.path.include?('cross_references')
                     # Handle comments on cross-references
                     CrossReference.find(params[:id])
                   else
                     nil
                   end
  end

  def ensure_frame_response
    return unless Rails.env.development?
    # Allow direct access if coming from admin or with direct_edit param
    return if params[:direct_edit] || request.referer&.include?('admin')
    redirect_to root_path unless turbo_frame_request?
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end