module RangeColors
  COLORS = [
    '#c45c26', # rust
    '#2a6f7f', # teal
    '#5c7a3a', # olive
    '#8a5a2b'  # umber
  ].freeze

  module_function

  def color_at(index)
    COLORS[index % COLORS.length]
  end
end
