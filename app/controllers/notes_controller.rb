class NotesController < ApplicationController
  before_action :authenticate_user!
  def index
    @notes = Note.all
  end

  def show
    @note = Note.find(params[:id])
    @comments = Comment.where(note_id: @note).all
  end

  def new
  end
  
  def create
    @note = Note.new(title: params['title'], content: params['content'], user_id: current_user.id)
    if @note.save
      redirect_to @note
    else
      render 'new'
    end
  end

  def destroy
    @note = current_user.notes.find(params[:id])
    @note.destroy
    redirect_to note_path
  end
end