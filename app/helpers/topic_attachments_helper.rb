module TopicAttachmentsHelper
  def topic_attachment_icon(attachment)
    if attachment.image?
      "fa-solid fa-image"
    elsif attachment.pdf?
      "fa-solid fa-file-pdf"
    elsif attachment.word?
      "fa-solid fa-file-word"
    else
      "fa-solid fa-file"
    end
  end
end
