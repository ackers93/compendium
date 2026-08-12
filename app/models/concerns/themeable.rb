# frozen_string_literal: true

module Themeable
  extend ActiveSupport::Concern

  THEME_KEYS = %w[primary header text background range_1 range_2 range_3 range_4].freeze
  HEX_COLOR = /\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/

  DEFAULT_THEME = {
    "primary" => "#be9627",
    "header" => "#1e3228",
    "text" => "#1a2e24",
    "background" => "#f3f5f3",
    "range_1" => "#c45c26",
    "range_2" => "#2a6f7f",
    "range_3" => "#5c7a3a",
    "range_4" => "#8a5a2b"
  }.freeze

  THEME_LABELS = {
    "primary" => "Accent / buttons",
    "header" => "Header background",
    "text" => "Text color",
    "background" => "Page background",
    "range_1" => "Range / chiasm color 1",
    "range_2" => "Range / chiasm color 2",
    "range_3" => "Range / chiasm color 3",
    "range_4" => "Range / chiasm color 4"
  }.freeze

  class_methods do
    def default_theme
      DEFAULT_THEME
    end
  end

  def resolved_theme
    prefs = (theme_preferences || {}).stringify_keys.slice(*THEME_KEYS)
    DEFAULT_THEME.merge(prefs.reject { |_k, v| v.blank? })
  end

  def theme_css_variables
    theme = resolved_theme
    primary = theme["primary"]

    {
      "--color-primary" => primary,
      "--color-primary-dark" => color_mix_toward(primary, "#000000", 0.22),
      "--color-primary-light" => color_mix_toward(primary, "#ffffff", 0.28),
      "--color-header" => theme["header"],
      "--color-header-text" => readable_on_dark(theme["header"]),
      "--color-text" => theme["text"],
      "--color-background" => theme["background"],
      "--color-surface" => "#ffffff",
      "--color-range-1" => theme["range_1"],
      "--color-range-2" => theme["range_2"],
      "--color-range-3" => theme["range_3"],
      "--color-range-4" => theme["range_4"]
    }
  end

  def update_theme_preferences(attrs)
    cleaned = sanitize_theme_attrs(attrs)
    return false if errors.any?

    update(theme_preferences: cleaned)
  end

  def reset_theme_preferences!
    update!(theme_preferences: {})
  end

  private

  def sanitize_theme_attrs(attrs)
    attrs = attrs.to_h.stringify_keys.slice(*THEME_KEYS)
    cleaned = {}

    attrs.each do |key, value|
      next if value.blank?

      hex = normalize_hex(value)
      unless hex.match?(HEX_COLOR)
        errors.add(:theme_preferences, "#{THEME_LABELS[key] || key} must be a valid hex color (e.g. #be9627)")
        next
      end

      cleaned[key] = hex.downcase
    end

    cleaned
  end

  def normalize_hex(value)
    value = value.to_s.strip
    value = "##{value}" unless value.start_with?("#")
    if value.match?(/\A#[0-9a-fA-F]{3}\z/)
      value = "#" + value[1..].chars.map { |c| c * 2 }.join
    end
    value
  end

  def color_mix_toward(hex, toward, amount)
    r1, g1, b1 = hex_to_rgb(hex)
    r2, g2, b2 = hex_to_rgb(toward)
    r = (r1 + (r2 - r1) * amount).round
    g = (g1 + (g2 - g1) * amount).round
    b = (b1 + (b2 - b1) * amount).round
    format("#%02x%02x%02x", r, g, b)
  end

  def readable_on_dark(hex)
    r, g, b = hex_to_rgb(hex)
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    luminance > 0.55 ? "#1a2e24" : "#b5c0b9"
  end

  def hex_to_rgb(hex)
    hex = normalize_hex(hex)
    [hex[1..2].to_i(16), hex[3..4].to_i(16), hex[5..6].to_i(16)]
  end
end
