class CommentsController < ApplicationController
  include ActionView::RecordIdentifier
  
  before_action :authenticate_user!
  before_action :set_comment, only: %i[ show edit update destroy ]
  before_action :ensure_frame_response, only: [:new, :edit]
  before_action :set_commentable, only: [:new, :create]

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
          render turbo_stream: [
            turbo_stream.append("comments", partial: "comments/comment", locals: { comment: @comment }),
            turbo_stream.replace("comment-form", partial: "comments/form", locals: { comment: @commentable.comments.build })
          ]
        }
        format.html { redirect_to @commentable, notice: "Comment was successfully created." }
        format.json { render json: { id: @comment.id, content: @comment.content }, status: :created, location: @comment }
      else
        format.turbo_stream { 
          # Just re-render the form with errors
          render turbo_stream: turbo_stream.replace("comment-form", 
            partial: "comments/form", locals: { comment: @comment }
          )
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
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("modal", ""),
            turbo_stream.replace(dom_id(@comment), partial: "comments/comment", locals: { comment: @comment })
          ]
        }
        format.html { redirect_to @comment.commentable, notice: "Comment was successfully updated." }
        format.json { render json: { id: @comment.id, content: @comment.content }, status: :ok, location: @comment }
      else
        format.turbo_stream { 
          # Re-render the edit modal with errors
          render turbo_stream: turbo_stream.replace("modal", 
            partial: "comments/edit", locals: { comment: @comment }
          )
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
    redirect_to @commentable
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def set_commentable
    @commentable = if params[:note_id]
                     Note.find(params[:note_id])
                   elsif params[:bible_verse_id]
                     BibleVerse.find(params[:bible_verse_id])
                   else
                     nil
                   end
  end

  def ensure_frame_response
    return unless Rails.env.development?
    redirect_to root_path unless turbo_frame_request?
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end