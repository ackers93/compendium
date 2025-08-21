class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note, only: %i[ show edit update destroy ]

  def index
    @notes = Note.order(created_at: :desc)
  end

  def show
    @commentable = @note
    @comment = @commentable.comments.build
    @comments = @commentable.comments
  end

  def new
    @note = Note.new
  end
  
  def edit
  end
  
  def create
    @note = Note.new(note_params)
    
    respond_to do |format|
      if @note.save
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("modal", ""),
            turbo_stream.prepend("notes", partial: "notes/note", locals: { note: @note }),
            turbo_stream.update("notice", "Note was successfully created.")
          ]
        }
        format.html { redirect_to note_url(@note), notice: "Note was successfully created." }
        format.json { render :show, status: :created, location: @note }
      else
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("modal", partial: "form", locals: { note: @note })
        }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @note.update(note_params)
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace(@note, partial: "notes/note", locals: { note: @note })
        }
        format.html { redirect_to note_url(@note), notice: "Note was successfully updated." }
        format.json { render :show, status: :ok, location: @note }
      else
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("modal", partial: "form", locals: { note: @note })
        }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @note.destroy

    respond_to do |format|
      format.html { redirect_to notes_url, notice: "Note was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def list
    @notes = Note.where('title ilike ?', "%#{params[:title]}%") if params[:title].present?
    render("index", locals: { notes: @notes })
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :content, :user_id, :tag_list)
  end
end