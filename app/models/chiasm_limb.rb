class ChiasmLimb < ApplicationRecord
  belongs_to :chiasm, inverse_of: :chiasm_limbs

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :start_offset, :end_offset, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :offsets_must_be_valid
  validate :must_not_overlap_siblings

  before_validation :set_position, on: :create, if: -> { chiasm.present? && position.blank? }

  def depth
    n = sibling_count
    return 0 if n.zero?

    index = zero_based_index
    [index, n - 1 - index].min
  end

  def label
    n = sibling_count
    return "A" if n.zero?

    index = zero_based_index
    if index < (n + 1) / 2
      letter_at(index)
    else
      "#{letter_at(n - 1 - index)}'"
    end
  end

  def color
    RangeColors.color_at(depth)
  end

  def center?
    n = sibling_count
    n.odd? && zero_based_index == n / 2
  end

  def text_slice
    passage = chiasm&.passage_text.to_s
    return "" if passage.empty? || start_offset.nil? || end_offset.nil?
    return "" if start_offset >= passage.length

    passage[start_offset...[end_offset, passage.length].min].to_s
  end

  private

  def sibling_count
    return chiasm.chiasm_limbs.reject(&:marked_for_destruction?).size if chiasm

    0
  end

  def zero_based_index
    return position.to_i - 1 if position.present?

    siblings = chiasm.chiasm_limbs.reject(&:marked_for_destruction?).sort_by { |l| l.position.to_i }
    siblings.index(self) || 0
  end

  def letter_at(index)
    ("A".ord + index).chr
  end

  def set_position
    max_position = chiasm.chiasm_limbs.maximum(:position) || 0
    self.position = max_position + 1
  end

  def offsets_must_be_valid
    return if start_offset.blank? || end_offset.blank? || chiasm.blank?

    if start_offset >= end_offset
      errors.add(:end_offset, "must be greater than start offset")
      return
    end

    passage_length = chiasm.passage_text.length
    if start_offset >= passage_length || end_offset > passage_length
      errors.add(:base, "limb offsets must fall within the passage")
    end
  end

  def must_not_overlap_siblings
    return if start_offset.blank? || end_offset.blank? || chiasm.blank?

    siblings = chiasm.chiasm_limbs.reject { |l| l == self || l.marked_for_destruction? }
    siblings.each do |other|
      next if other.start_offset.blank? || other.end_offset.blank?
      next if end_offset <= other.start_offset || start_offset >= other.end_offset

      errors.add(:base, "limb overlaps another limb")
      break
    end
  end
end
