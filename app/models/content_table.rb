class ContentTable < ApplicationRecord
  include ActionText::Attachable

  MAX_COLUMNS = 20
  MAX_ROWS = 50

  STYLE_KEYS = %w[
    header_row header_column header_bg header_text
    body_bg body_text stripe_bg border_color border_width
    text_align show_title
  ].freeze

  DEFAULT_STYLE = {
    "header_row" => true,
    "header_column" => false,
    "header_bg" => "#1e3228",
    "header_text" => "#ffffff",
    "body_bg" => "#ffffff",
    "body_text" => "#1a2e24",
    "stripe_bg" => "#f3f5f3",
    "border_color" => "#d4dbd6",
    "border_width" => 1,
    "text_align" => "left",
    "show_title" => true
  }.freeze

  COLOR_PATTERN = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/
  TEXT_ALIGNS = %w[left center right].freeze

  belongs_to :user

  validates :title, presence: true, length: { maximum: 200 }
  validates :column_count, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_COLUMNS }
  validates :row_count, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_ROWS }
  validate :cells_must_match_dimensions
  validate :style_must_be_allowed

  before_validation :normalize_cells_and_style

  def self.default_cells(rows, cols)
    Array.new(rows) { Array.new(cols, "") }
  end

  def style_with_defaults
    DEFAULT_STYLE.merge((style || {}).stringify_keys.slice(*STYLE_KEYS))
  end

  def css_variables
    s = style_with_defaults
    {
      "--ct-header-bg" => s["header_bg"],
      "--ct-header-text" => s["header_text"],
      "--ct-body-bg" => s["body_bg"],
      "--ct-body-text" => s["body_text"],
      "--ct-stripe-bg" => s["stripe_bg"],
      "--ct-border-color" => s["border_color"],
      "--ct-border-width" => "#{s["border_width"].to_i}px",
      "--ct-text-align" => s["text_align"]
    }
  end

  def header_row?
    ActiveModel::Type::Boolean.new.cast(style_with_defaults["header_row"])
  end

  def header_column?
    ActiveModel::Type::Boolean.new.cast(style_with_defaults["header_column"])
  end

  def show_title?
    ActiveModel::Type::Boolean.new.cast(style_with_defaults["show_title"])
  end

  def cell_at(row, col)
    cells&.dig(row, col).to_s
  end

  def to_trix_content_attachment_partial_path
    "content_tables/editor"
  end

  def to_attachable_partial_path
    "content_tables/content_table"
  end

  def attachable_content_type
    "application/vnd.actiontext.content_table"
  end

  def attachable_filename
    title.presence || "Table"
  end

  def previewable_attachable?
    true
  end

  private

  def normalize_cells_and_style
    self.column_count = column_count.to_i if column_count.present?
    self.row_count = row_count.to_i if row_count.present?

    rows = [row_count.to_i, 1].max
    cols = [column_count.to_i, 1].max
    raw = cells.is_a?(Array) ? cells : []

    self.cells = Array.new(rows) do |r|
      row = raw[r].is_a?(Array) ? raw[r] : []
      Array.new(cols) { |c| row[c].to_s }
    end

    merged = DEFAULT_STYLE.merge((style || {}).stringify_keys.slice(*STYLE_KEYS))
    merged["header_row"] = ActiveModel::Type::Boolean.new.cast(merged["header_row"])
    merged["header_column"] = ActiveModel::Type::Boolean.new.cast(merged["header_column"])
    merged["show_title"] = ActiveModel::Type::Boolean.new.cast(merged["show_title"])
    merged["border_width"] = merged["border_width"].to_i.clamp(0, 8)
    merged["text_align"] = TEXT_ALIGNS.include?(merged["text_align"].to_s) ? merged["text_align"].to_s : "left"
    self.style = merged
  end

  def cells_must_match_dimensions
    return if cells.blank? || column_count.blank? || row_count.blank?
    return unless cells.is_a?(Array)

    unless cells.length == row_count && cells.all? { |row| row.is_a?(Array) && row.length == column_count }
      errors.add(:cells, "must be a #{row_count}×#{column_count} grid")
    end
  end

  def style_must_be_allowed
    return if style.blank?

    s = style.stringify_keys
    %w[header_bg header_text body_bg body_text stripe_bg border_color].each do |key|
      next if s[key].blank?
      errors.add(:style, "#{key} must be a hex color") unless s[key].to_s.match?(COLOR_PATTERN)
    end

    if s["text_align"].present? && !TEXT_ALIGNS.include?(s["text_align"].to_s)
      errors.add(:style, "text_align must be left, center, or right")
    end
  end
end
