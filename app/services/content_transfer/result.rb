# frozen_string_literal: true

module ContentTransfer
  Result = Struct.new(
    :imported_count,
    :skipped_count,
    :failed_count,
    :missing_authors,
    :errors,
    keyword_init: true
  ) do
    def summary
      parts = ["Imported #{imported_count}", "skipped #{skipped_count}"]
      parts << "failed #{failed_count}" if failed_count.to_i.positive?
      if missing_authors.present?
        parts << "assigned #{missing_authors.size} missing #{'author'.pluralize(missing_authors.size)} to you"
      end
      parts.join(", ") + "."
    end
  end
end
