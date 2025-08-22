class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note, only: %i[ show edit update destroy ]

  def index
    @notes = Note.order(created_at: :desc)
  end

  def show
    @commentable = @note
    @comment = @commentable.comments.build
    @comments = Comment.where(commentable: @note).includes(:user, :rich_text_content).order(created_at: :desc)
  end

  def new
    @note = Note.new
  end
  
  def edit
  end
  
  def create
    @note = Note.new(note_params)
    @note.user = current_user

    respond_to do |format|
      if @note.save
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("modal", ""),  # Close the modal
            turbo_stream.prepend("notes-table-body", partial: "notes/note_row", locals: { note: @note })  # Add to table body
          ]
        }
        format.html { redirect_to notes_path, notice: "Note was successfully created." }
        format.json { render json: { id: @note.id, title: @note.title }, status: :created, location: @note }
      else
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("modal", partial: "notes/new", locals: { note: @note })
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
          render turbo_stream: [
            turbo_stream.replace("modal", ""),  # Close the modal
            turbo_stream.replace("note-content", partial: "notes/note_content", locals: { note: @note })  # Update the note content
          ]
        }
        format.html { redirect_to @note, notice: "Note was successfully updated." }
        format.json { render json: { id: @note.id, title: @note.title }, status: :ok, location: @note }
      else
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace("modal", partial: "notes/edit", locals: { note: @note })
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
    @notes = if params[:query].present?
               Note.joins(:rich_text_content)
                   .joins("LEFT JOIN taggings ON taggings.taggable_id = notes.id AND taggings.taggable_type = 'Note'")
                   .joins("LEFT JOIN tags ON tags.id = taggings.tag_id")
                   .where("LOWER(notes.title) LIKE LOWER(?) OR LOWER(action_text_rich_texts.body) LIKE LOWER(?) OR LOWER(tags.name) LIKE LOWER(?)", 
                          "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
                   .distinct
                   .order(created_at: :desc)
             else
               Note.order(created_at: :desc)
             end
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("notes-table", partial: "notes/table", locals: { notes: @notes })
      end
      format.html { render "index" }
    end
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :content, :tag_list)
  end
end