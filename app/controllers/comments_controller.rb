class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: %i[ show edit update destroy ]
  before_action :ensure_frame_response, only: [:new, :edit]

    def index
      puts "com#index"
      @comments = Comment.all
    end
  
    def show
      puts "com#show"
      @comment = Comment.find(params[:id])
      @note = Note.where(id: @comment.note_id)
    end
  
    def new
      puts "com#new"
      @comment = Comment.new
    end

    def edit
      puts "com#edit"
      @comment = Comment.find(params[:id])
      @note = Note.find(@comment.note_id)
      puts "COMMENT #{@comment.inspect}"
    end

    def update
      puts "com#update"
      @comment = Comment.find(params[:id])
      @note = Note.where(id: @comment.note_id)
      respond_to do |format|
        if @comment.update(comment_params)
          format.turbo_stream { render turbo_stream: turbo_stream.replace(@comment, partial: "comments/comment", locals: {comment: @comment}) }
          format.html { redirect_to note_url(@note), notice: "Comment was successfully updated." }
          format.json { render :show, status: :ok, location: @note }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @comment.errors, status: :unprocessable_entity }
        end
      end
    end
    
    def create
      puts "com#create"
      puts "COMMENTPARAMS #{comment_params}"
      @comment = Comment.new(comment_params)
      respond_to do |format|
        if @comment.save
          format.turbo_stream { render turbo_stream: turbo_stream.prepend('comments', partial: 'comments/comment', locals: {comment: @comment}) }
          format.html { redirect_to comment_url(@comment), notice: "Comment was successfully created." }
          format.json { render :show, status: :created, location: @comment }
        else
          puts "ERROR #{@comment.errors.full_messages}"
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @comment.errors, status: :unprocessable_entity }
        end
      end
    end
  
    def destroy
      puts "com#des"
      @comment = Comment.find(params[:id])
      @commentid = @comment.note_id
      @comment.destroy
      redirect_to note_path(@commentid)
    end


    private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    def ensure_frame_response
      return unless Rails.env.development?
      redirect_to root_path unless turbo_frame_request?
    end

    # Only allow a list of trusted parameters through.
    def comment_params
      params.require(:comment).permit(:content, :note_id, :user_id)
    end
  end