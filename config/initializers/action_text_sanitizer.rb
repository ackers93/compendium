# frozen_string_literal: true

# Allow content-table embeds (styled HTML tables) inside Action Text output.
Rails.application.config.to_prepare do
  tags = ActionText::ContentHelper.sanitizer.class.allowed_tags.to_a
  attrs = ActionText::ContentHelper.sanitizer.class.allowed_attributes.to_a

  ActionText::ContentHelper.allowed_tags = (
    tags + %w[
      action-text-attachment figure figcaption
      table thead tbody tfoot tr th td colgroup col
      div span br
    ]
  ).uniq

  ActionText::ContentHelper.allowed_attributes = (
    attrs + %w[
      style class data-content-table-id
      colspan rowspan scope
      target rel
    ]
  ).uniq
end
