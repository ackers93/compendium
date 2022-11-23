class CommentsController < ApplicationController
    before_action :authenticate_user!
    def index
      @notes = Comment.all
    end
  
    def show
      @comment = Comment.find(params[:id])
    end
  
    def new
    end
    
    def create
      @commentid = params['note_id']
      @comment = Comment.new(content: params['content'], note_id: params['note_id'], user_id: current_user.id)
      if @comment.save
        redirect_to note_path(@commentid)
      else
        render note_path(@commentid)
      end
    end
  
    def destroy
      @comment = Comment.find(params[:note_id])
      puts "COMDES #{@comment}"
      @commentid = @comment.note_id
      puts "COMIDDES #{@commentid}"
      @comment.destroy
      redirect_to note_path(@commentid)
    end
  end