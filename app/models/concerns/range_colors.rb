module RangeColors
  COUNT = 4

  # Default hex values — mirrored in Themeable::DEFAULT_THEME and :root CSS.
  COLORS = [
    Themeable::DEFAULT_THEME.fetch("range_1"),
    Themeable::DEFAULT_THEME.fetch("range_2"),
    Themeable::DEFAULT_THEME.fetch("range_3"),
    Themeable::DEFAULT_THEME.fetch("range_4")
  ].freeze

  module_function

  def color_at(index)
    css_var_at(index)
  end

  def css_var_at(index)
    "var(--color-range-#{(index % COUNT) + 1})"
  end

  def hex_at(index)
    COLORS[index % COUNT]
  end
end
