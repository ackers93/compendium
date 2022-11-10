class NoteController < ApplicationController
  before_action :authenticate_user!
  def index
    @notes = Note.all
  end

  def show
    @note = Note.find(params[:id])
  end

  def new
    puts "PARAAMSNEW #{params}"
    puts "noteNEW"
  end
  
  def create
    puts "noteCREATE"
    puts "PARAAMSCREATE #{params}"
    @note = Note.new(title: params['title'], content: params['content'], user_id: current_user.id)
    if @note.save
      redirect_to note_path
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