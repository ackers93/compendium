class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: %i[ show edit update destroy ]
  before_action :ensure_frame_response, only: [:new, :edit]

    def index
      @comments = Comment.all
    end
  
    def show
      @comment = Comment.find(params[:id])
    end
  
    def new
      @comment = Comment.new
    end

    def edit
      @note = Note.find(params[:note_id])
      puts "EDITNOTE #{@note.inspect}"
      @comment = Comment.find(params[:id])
      puts "EDITCOMMENT #{@comment.inspect}"
      @commentid = @comment.note_id
      puts "EDITCOMID #{@commentid}"
    end
    
    def create
      puts "COMMENTPARAMS #{comment_params}"
      # respond_to do |format|
      #   if @comment.save
      #     format.turbo_stream { render turbo_stream: turbo_stream.prepend('comments', partial: 'comments/comment', locals: {comment: @comment}) }
      #     format.html { redirect_to comment_url(@comment), notice: "Comment was successfully created." }
      #     format.json { render :show, status: :created, location: @comment }
      #   else
      #     puts "ERROR #{@comment.errors.full_messages}"
      #     format.html { render :new, status: :unprocessable_entity }
      #     format.json { render json: @comment.errors, status: :unprocessable_entity }
      #   end
      # end
    end
  
    def destroy
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