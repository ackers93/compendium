class TopicAttachment < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[
    image/png
    image/jpeg
    image/gif
    image/webp
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  MAX_FILE_BYTES = 25.megabytes

  belongs_to :topic
  belongs_to :user

  has_one_attached :file

  validate :file_must_be_attached
  validate :file_must_be_acceptable

  def filename
    file.attached? ? file.filename.to_s : "file"
  end

  def image?
    file.attached? && file.content_type.to_s.start_with?("image/")
  end

  def pdf?
    file.attached? && file.content_type == "application/pdf"
  end

  def word?
    return false unless file.attached?

    %w[
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].include?(file.content_type)
  end

  def content_type_label
    return "Image" if image?
    return "PDF" if pdf?
    return "Word" if word?

    "File"
  end

  private

  def file_must_be_attached
    errors.add(:file, "can't be blank") unless file.attached?
  end

  def file_must_be_acceptable
    return unless file.attached?

    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      errors.add(:file, "must be an image, PDF, or Word document")
    end

    if file.byte_size.to_i > MAX_FILE_BYTES
      errors.add(:file, "must be 25 MB or smaller")
    end
  end
end
