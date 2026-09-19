require "csv"

class CsvImportsController < ApplicationController
  include Authorizable
  include BulkUploadHubRendering

  before_action :authenticate_user!
  before_action :authorize_create!

  def create
    @csv_text = params[:csv_text].to_s
    source = csv_source

    if source.nil?
      flash.now[:alert] = "Attach a CSV file or paste CSV text to import."
      render_bulk_upload_hub(active_tab: "csv")
      return
    end

    if source == :invalid_file
      flash.now[:alert] = "Upload a .csv file, or paste CSV text instead."
      render_bulk_upload_hub(active_tab: "csv")
      return
    end

    result = Imports::CsvNotesImporter.call(user: current_user, io_or_string: source)
    @import_result = result

    if result.failed_count.zero? && (result.imported_count.positive? || result.skipped.values.sum.positive?)
      redirect_to bulk_upload_hub_path(tab: "csv"),
                  notice: import_notice(result)
    else
      flash.now[:alert] = import_alert(result)
      render_bulk_upload_hub(active_tab: "csv")
    end
  rescue CSV::MalformedCSVError
    flash.now[:alert] = "That text could not be read as CSV. Check for unescaped quotes and try again."
    render_bulk_upload_hub(active_tab: "csv")
  end

  private

  def csv_source
    file = params[:file]
    pasted = params[:csv_text].to_s

    if file.present?
      return file if csv_upload?(file)

      return :invalid_file
    end

    pasted.strip.presence
  end

  def csv_upload?(file)
    filename = file.original_filename.to_s.downcase
    filename.end_with?(".csv") || file.content_type.to_s.include?("csv")
  end

  def import_notice(result)
    parts = []
    if result.imported_count.positive?
      parts << "Imported #{result.imported_count} #{'comment'.pluralize(result.imported_count)}"
    end
    parts.concat(skip_summary_parts(result.skipped))
    return "No comments were imported." if parts.empty?

    parts.join("; ") + "."
  end

  def import_alert(result)
    parts = []
    parts << "#{result.imported_count} #{'comment'.pluralize(result.imported_count)} imported" if result.imported_count.positive?
    parts << "#{result.failed_count} #{'row'.pluralize(result.failed_count)} failed" if result.failed_count.positive?
    parts.concat(skip_summary_parts(result.skipped))
    return "No comments were imported." if parts.empty?

    parts.join(". ") + "."
  end

  def skip_summary_parts(skipped)
    parts = []
    duplicate_count = skipped[:duplicate].to_i
    other_skipped = skipped.except(:duplicate).values.sum
    parts << "skipped #{duplicate_count} #{'duplicate'.pluralize(duplicate_count)}" if duplicate_count.positive?
    parts << "skipped #{other_skipped} other #{'row'.pluralize(other_skipped)}" if other_skipped.positive?
    parts
  end
end
