require "csv"

class OliveTreeImportsController < ApplicationController
  include Authorizable
  include BulkUploadHubRendering

  before_action :authenticate_user!
  before_action :authorize_create!

  def create
    file = params[:file]

    if file.blank?
      flash.now[:alert] = "Choose an Olive Tree CSV export to import."
      render_bulk_upload_hub(active_tab: "olive_tree")
      return
    end

    unless csv_upload?(file)
      flash.now[:alert] = "Upload a .csv file exported from Olive Tree."
      render_bulk_upload_hub(active_tab: "olive_tree")
      return
    end

    result = Imports::OliveTreeNotesImporter.call(user: current_user, io_or_string: file)
    @import_result = result

    if result.failed_count.zero? && (result.imported_count.positive? || result.skipped.values.sum.positive?)
      redirect_to bulk_upload_hub_path(tab: "olive_tree"),
                  notice: import_notice(result)
    else
      flash.now[:alert] = import_alert(result)
      render_bulk_upload_hub(active_tab: "olive_tree")
    end
  rescue CSV::MalformedCSVError
    flash.now[:alert] = "That file could not be read as a CSV. Re-download the Olive Tree export and try again."
    render_bulk_upload_hub(active_tab: "olive_tree")
  end

  private

  def csv_upload?(file)
    filename = file.original_filename.to_s.downcase
    filename.end_with?(".csv") || file.content_type.to_s.include?("csv")
  end

  def import_notice(result)
    parts = []
    if result.imported_count.positive?
      parts << "Imported #{result.imported_count} #{'note'.pluralize(result.imported_count)}"
    end
    parts.concat(skip_summary_parts(result.skipped))
    return "No notes were imported." if parts.empty?

    parts.join("; ") + "."
  end

  def import_alert(result)
    parts = []
    parts << "#{result.imported_count} #{'note'.pluralize(result.imported_count)} imported" if result.imported_count.positive?
    parts << "#{result.failed_count} #{'row'.pluralize(result.failed_count)} failed" if result.failed_count.positive?
    parts.concat(skip_summary_parts(result.skipped))
    return "No notes were imported." if parts.empty?

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
