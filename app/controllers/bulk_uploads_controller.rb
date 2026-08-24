class BulkUploadsController < ApplicationController
  include Authorizable
  include BulkUploadHubRendering

  before_action :authenticate_user!
  before_action :authorize_create!

  def new
    redirect_to bulk_upload_hub_path(tab: "comments")
  end

  def create
    @comment_rows = []
    success_count = 0

    entries = normalize_entries(params[:entries])

    if entries.none? { |entry| entry[:reference].to_s.strip.present? || entry[:content].to_s.strip.present? }
      flash.now[:alert] = "Add at least one verse and comment to upload."
      @comment_rows = default_comment_rows
      render_bulk_upload_hub(active_tab: "comments")
      return
    end

    entries.each_with_index do |entry, index|
      reference = entry[:reference].to_s.strip
      content = entry[:content].to_s.strip

      @comment_rows << { reference: reference, content: content, result: nil }

      next if reference.blank? && content.blank?

      if reference.blank?
        record_comment_error(index, "Verse reference is required")
        next
      end

      if content.blank?
        record_comment_error(index, "Comment is required")
        next
      end

      parsed = VerseReferenceParser.parse(reference)
      unless parsed
        message = "Could not parse \"#{reference}\". Try formats like gen1:1, Gen 1:1, or Genesis 1:1-4."
        record_comment_error(index, message)
        next
      end

      verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.start_verse)
      unless verse
        message = "Verse not found: #{parsed.display}"
        record_comment_error(index, message)
        next
      end

      comment = Comment.new(user: current_user, commentable: verse, content: content)

      if parsed.end_verse
        end_verse = BibleVerse.find_by(book: parsed.book, chapter: parsed.chapter, verse: parsed.end_verse)
        unless end_verse
          message = "End verse not found: #{parsed.book} #{parsed.chapter}:#{parsed.end_verse}"
          record_comment_error(index, message)
          next
        end
        comment.end_verse = end_verse
      end

      if comment.save
        success_count += 1
        @comment_rows.last[:result] = { success: true, reference: comment.verse_reference }
      else
        record_comment_error(index, comment.errors.full_messages.to_sentence)
      end
    end

    if success_count.positive? && @comment_rows.none? { |row| row[:result]&.dig(:error) }
      redirect_to bulk_upload_hub_path(tab: "comments"),
                  notice: "Successfully uploaded #{success_count} #{'comment'.pluralize(success_count)}."
    else
      flash.now[:alert] = build_comment_result_flash(success_count) if @comment_rows.any? { |row| row[:result]&.dig(:error) }
      render_bulk_upload_hub(active_tab: "comments")
    end
  end

  private

  def record_comment_error(index, message)
    @comment_rows[index][:result] = { error: message }
  end

  def normalize_entries(entries_param)
    return [] if entries_param.blank?

    if entries_param.is_a?(ActionController::Parameters) || entries_param.is_a?(Hash)
      entries_param.values
    else
      Array(entries_param)
    end.map do |entry|
      entry = entry.permit(:reference, :content) if entry.respond_to?(:permit)
      {
        reference: entry[:reference],
        content: entry[:content]
      }
    end
  end

  def build_comment_result_flash(success_count)
    failed_count = @comment_rows.count { |row| row[:result]&.dig(:error) }
    parts = []
    parts << "#{success_count} #{'comment'.pluralize(success_count)} uploaded" if success_count.positive?
    parts << "#{failed_count} #{'row'.pluralize(failed_count)} need attention" if failed_count.positive?
    parts.join(". ") + "."
  end
end
