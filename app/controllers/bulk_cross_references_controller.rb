class BulkCrossReferencesController < ApplicationController
  include Authorizable
  include BulkUploadHubRendering

  before_action :authenticate_user!
  before_action :authorize_create!

  def new
    redirect_to bulk_upload_hub_path(tab: "cross_references")
  end

  def create
    @xref_rows = []
    success_count = 0

    entries = normalize_entries(params[:entries])

    if entries.none? { |entry| row_filled?(entry) }
      flash.now[:alert] = "Add at least one source and target verse to upload."
      @xref_rows = default_xref_rows
      render_bulk_upload_hub(active_tab: "cross_references")
      return
    end

    entries.each_with_index do |entry, index|
      source_reference = entry[:source_reference].to_s.strip
      target_reference = entry[:target_reference].to_s.strip
      content = entry[:content].to_s.strip

      @xref_rows << {
        source_reference: source_reference,
        target_reference: target_reference,
        content: content,
        result: nil
      }

      next unless row_filled?(entry)

      if source_reference.blank?
        record_xref_error(index, "Source verse is required")
        next
      end

      if target_reference.blank?
        record_xref_error(index, "Target verse is required")
        next
      end

      source = VerseReferenceResolver.call(source_reference, allow_range: false)
      if source.error
        record_xref_error(index, "Source: #{source.error}")
        next
      end

      target = VerseReferenceResolver.call(target_reference, allow_range: true)
      if target.error
        record_xref_error(index, "Target: #{target.error}")
        next
      end

      result = create_cross_reference(
        source_verse: source.verse,
        target_verse: target.verse,
        target_end_verse: target.end_verse,
        content: content
      )

      if result[:error]
        record_xref_error(index, result[:error])
      else
        success_count += 1
        @xref_rows.last[:result] = { success: true, reference: result[:reference] }
      end
    end

    if success_count.positive? && @xref_rows.none? { |row| row[:result]&.dig(:error) }
      redirect_to bulk_upload_hub_path(tab: "cross_references"),
                  notice: "Successfully uploaded #{success_count} cross-#{'reference'.pluralize(success_count)}."
    else
      flash.now[:alert] = build_xref_result_flash(success_count) if @xref_rows.any? { |row| row[:result]&.dig(:error) }
      render_bulk_upload_hub(active_tab: "cross_references")
    end
  end

  private

  def create_cross_reference(source_verse:, target_verse:, target_end_verse:, content:)
    if source_verse.id == target_verse.id || (target_end_verse && source_verse.id == target_end_verse.id)
      return { error: "Source and target verses must be different" }
    end

    existing_ref = CrossReference.find_by(
      "(source_verse_id = ? AND target_verse_id = ?) OR (source_verse_id = ? AND target_verse_id = ?)",
      source_verse.id, target_verse.id, target_verse.id, source_verse.id
    )

    if existing_ref
      if content.present?
        comment = existing_ref.comments.build(content: content, user: current_user)
        unless comment.save
          return { error: comment.errors.full_messages.to_sentence }
        end
      end

      return { reference: existing_ref.connection_label }
    end

    cross_reference = CrossReference.new(
      source_verse: source_verse,
      target_verse: target_verse,
      target_end_verse: target_end_verse,
      user: current_user
    )

    unless cross_reference.save
      return { error: cross_reference.errors.full_messages.to_sentence }
    end

    if content.present?
      comment = cross_reference.comments.build(content: content, user: current_user)
      unless comment.save
        return { error: comment.errors.full_messages.to_sentence }
      end
    end

    { reference: cross_reference.connection_label }
  end

  def record_xref_error(index, message)
    @xref_rows[index][:result] = { error: message }
  end

  def row_filled?(entry)
    entry[:source_reference].to_s.strip.present? ||
      entry[:target_reference].to_s.strip.present? ||
      entry[:content].to_s.strip.present?
  end

  def normalize_entries(entries_param)
    return [] if entries_param.blank?

    entries = if entries_param.is_a?(ActionController::Parameters) || entries_param.is_a?(Hash)
                entries_param.values
              else
                Array(entries_param)
              end

    entries.map do |entry|
      entry = entry.permit(:source_reference, :target_reference, :content) if entry.respond_to?(:permit)
      {
        source_reference: entry[:source_reference],
        target_reference: entry[:target_reference],
        content: entry[:content]
      }
    end
  end

  def build_xref_result_flash(success_count)
    failed_count = @xref_rows.count { |row| row[:result]&.dig(:error) }
    parts = []
    parts << "#{success_count} cross-#{'reference'.pluralize(success_count)} uploaded" if success_count.positive?
    parts << "#{failed_count} #{'row'.pluralize(failed_count)} need attention" if failed_count.positive?
    parts.join(". ") + "."
  end
end
