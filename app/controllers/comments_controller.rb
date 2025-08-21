class CommentsController < ApplicationController
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
    respond_to do |format|
      if @comment.save
        format.turbo_stream { render turbo_stream: turbo_stream.prepend('comments', partial: 'comments/comment', locals: { comment: @comment }) }
        format.html { redirect_to @commentable, notice: "Comment was successfully created." }
        format.json { render :show, status: :created, location: @comment }
      else
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
    @comment = Comment.find(params[:id])
    @commentable = @comment.commentable
    respond_to do |format|
      if @comment.update(comment_params)
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@comment, partial: "comments/comment", locals: { comment: @comment }) }
        format.html { redirect_to @commentable, notice: "Comment was successfully updated." }
        format.json { render :show, status: :ok, location: @commentable }
      else
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
                   end
  end

  def ensure_frame_response
    return unless Rails.env.development?
    redirect_to root_path unless turbo_frame_request?
  end

  def comment_params
    params.require(:comment).permit(:content, :user_id)
  end
end