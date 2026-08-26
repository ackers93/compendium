module ValidatesInlineImages
  extend ActiveSupport::Concern

  ALLOWED_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_BYTES = 5.megabytes

  included do
    validate :inline_images_must_be_acceptable
  end

  private

  def inline_images_must_be_acceptable
    rich_text = content
    return unless rich_text.respond_to?(:body) && rich_text.body.present?

    rich_text.body.attachables.grep(ActiveStorage::Blob).each do |blob|
      unless ALLOWED_TYPES.include?(blob.content_type)
        errors.add(:base, "Inline attachments must be images (PNG, JPEG, GIF, or WebP)")
        break
      end

      if blob.byte_size.to_i > MAX_BYTES
        errors.add(:base, "Inline images must be 5 MB or smaller")
        break
      end
    end
  end
end
