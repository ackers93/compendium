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
    @comment = Comment.new(commentable: @commentable)
    assign_parent(@comment, params[:parent_id])
  end

  def create
    @page_commentable = @commentable
    @comment = Comment.new(comment_params.except(:parent_id))
    @comment.user = current_user
    @comment.commentable = @commentable

    assign_parent(@comment, comment_params[:parent_id])
    end_verse_error = @comment.reply? ? nil : resolve_end_verse(@comment, @comment.commentable)

    respond_to do |format|
      if end_verse_error
        @comment.errors.add(:end_verse, end_verse_error)
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("comment-form",
              partial: "comments/form", locals: { comment: @comment }
            )
          ]
        }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      elsif @comment.save
        format.turbo_stream { 
          if @page_commentable.is_a?(CrossReference)
            render turbo_stream: [
              turbo_stream.replace("cross-references", 
                partial: "cross_references/cross_references_list", 
                locals: { cross_references: @page_commentable.source_verse.ordered_cross_references, verse: @page_commentable.source_verse }
              ),
              turbo_stream.replace("modal", "")
            ]
          elsif @comment.reply?
            render turbo_stream: [
              turbo_stream.append(dom_id(@comment.parent, :replies),
                partial: "comments/comment",
                locals: {
                  comment: @comment,
                  children_by_parent: {},
                  page_verse: @page_commentable.is_a?(BibleVerse) ? @page_commentable : nil,
                  depth: @comment.depth
                }
              ),
              turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @page_commentable }),
              turbo_stream.replace("modal", "")
            ]
          elsif display_comments_count(@page_commentable) == 1
            render turbo_stream: [
              turbo_stream.update("comments", partial: "comments/comments_list", locals: { commentable: @page_commentable }),
              turbo_stream.replace("comment-form", partial: "comments/form", locals: { comment: @page_commentable.comments.build, page_commentable: @page_commentable }),
              turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @page_commentable }),
              turbo_stream.replace("modal", "")
            ]
          else
            render turbo_stream: [
              turbo_stream.prepend("comments",
                partial: "comments/comment",
                locals: {
                  comment: @comment,
                  children_by_parent: {},
                  page_verse: @page_commentable.is_a?(BibleVerse) ? @page_commentable : nil,
                  depth: 0
                }
              ),
              turbo_stream.replace("comment-form", partial: "comments/form", locals: { comment: @page_commentable.comments.build, page_commentable: @page_commentable }),
              turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @page_commentable }),
              turbo_stream.replace("modal", "")
            ]
          end
        }
        format.html { 
          if @page_commentable.is_a?(CrossReference)
            redirect_to root_path
          elsif @page_commentable.is_a?(BibleVerse)
            redirect_to bible_verse_show_path(book: @page_commentable.book, chapter: @page_commentable.chapter, verse: @page_commentable.verse), notice: "Comment was successfully created."
          else
            redirect_to @page_commentable, notice: "Comment was successfully created."
          end
        }
        format.json { render json: { id: @comment.id, content: @comment.content }, status: :created, location: @comment }
      else
        format.turbo_stream { 
          if @page_commentable.is_a?(CrossReference)
            render turbo_stream: turbo_stream.replace("modal", 
              partial: "cross_references/new_comment", locals: { cross_ref: @page_commentable, comment: @comment }
            )
          elsif @comment.reply?
            @commentable = @page_commentable
            render turbo_stream: turbo_stream.replace(
              "modal",
              html: render_to_string(template: "comments/new", layout: false)
            )
          else
            render turbo_stream: [
              turbo_stream.replace("comment-form", 
                partial: "comments/form", locals: { comment: @comment, page_commentable: @page_commentable }
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
    end_verse_error = @comment.reply? ? nil : resolve_end_verse(@comment, @comment.commentable)

    respond_to do |format|
      if end_verse_error
        @comment.errors.add(:end_verse, end_verse_error)
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace("modal",
              partial: "comments/edit", locals: { comment: @comment }
            )
          ]
        }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      elsif @comment.update(comment_params.except(:parent_id))
        notice_message = if @comment.flagged_content_was_updated
          "Comment was successfully updated and has been submitted back to admins for review. Thank you for addressing the feedback!"
        else
          "Comment was successfully updated."
        end
        
        format.turbo_stream { 
          if @comment.commentable.is_a?(CrossReference)
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
              turbo_stream.replace(dom_id(@comment, :body),
                partial: "comments/comment_body",
                locals: {
                  comment: @comment,
                  page_verse: @comment.commentable.is_a?(BibleVerse) ? @comment.commentable : nil,
                  depth: @comment.depth,
                  has_replies: @comment.replies.exists?
                }
              )
            ]
          end
        }
        format.html { 
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
    page_verse = page_verse_for_comment(@comment)
    @comment.destroy
    
    respond_to do |format|
      format.turbo_stream { 
        if @commentable.is_a?(CrossReference)
          render turbo_stream: [
            turbo_stream.replace("comments-summary-#{@commentable.id}", 
              partial: "cross_references/comments_summary", locals: { cross_ref: @commentable }
            )
          ]
        elsif @commentable.is_a?(BibleVerse)
          render turbo_stream: [
            turbo_stream.update("comments", partial: "comments/comments_list", locals: { commentable: page_verse }),
            turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: page_verse })
          ]
        else
          render turbo_stream: [
            turbo_stream.update("comments", partial: "comments/comments_list", locals: { commentable: @commentable }),
            turbo_stream.replace("comment-count", partial: "comments/comment_count", locals: { commentable: @commentable })
          ]
        end
      }
      format.html { 
        if @commentable.is_a?(BibleVerse)
          redirect_to bible_verse_show_path(book: page_verse.book, chapter: page_verse.chapter, verse: page_verse.verse), notice: "Comment was successfully deleted."
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
                     CrossReference.find(params[:id])
                   else
                     nil
                   end
  end

  def ensure_frame_response
    return unless Rails.env.development?
    return if params[:direct_edit] || request.referer&.include?('admin')
    redirect_to root_path unless turbo_frame_request?
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end

  def assign_parent(comment, parent_id)
    return if parent_id.blank?

    parent = Comment.find_by(id: parent_id)
    return unless parent && reply_allowed?(parent, @commentable || comment.commentable)

    comment.parent = parent
    comment.commentable = parent.commentable
    comment.end_verse = nil
  end

  def reply_allowed?(parent, page_commentable)
    return false unless page_commentable
    return true if parent.commentable == page_commentable

    page_commentable.is_a?(BibleVerse) &&
      parent.commentable.is_a?(BibleVerse) &&
      parent.involves_verse?(page_commentable)
  end

  def resolve_end_verse(comment, commentable)
    return nil unless commentable.is_a?(BibleVerse)
    return nil unless params[:comment]&.key?(:end_verse) || params[:comment]&.key?("end_verse")

    end_verse_param = params.dig(:comment, :end_verse)
    if end_verse_param.blank?
      comment.end_verse = nil
      return nil
    end

    found = BibleVerse.find_by(
      book: commentable.book,
      chapter: commentable.chapter,
      verse: end_verse_param.to_i
    )
    return "not found" unless found

    comment.end_verse = found
    nil
  end

  def display_comments_count(commentable)
    if commentable.is_a?(BibleVerse)
      commentable.visible_comments.count
    else
      commentable.comments.count
    end
  end

  def page_verse_for_comment(comment)
    return comment.commentable unless comment.commentable.is_a?(BibleVerse)

    if params[:book] && params[:chapter] && params[:verse_number]
      found = BibleVerse.find_by(book: params[:book], chapter: params[:chapter].to_i, verse: params[:verse_number].to_i)
      return found if found && comment.involves_verse?(found)
    end

    if request.referer
      referer_path = URI.parse(request.referer).path rescue nil
      if referer_path&.match(%r{/bible_verses/([^/]+)/(\d+)/(\d+)})
        found = BibleVerse.find_by(book: CGI.unescape($1), chapter: $2.to_i, verse: $3.to_i)
        return found if found && comment.involves_verse?(found)
      end
    end

    comment.commentable
  end
end
