require "test_helper"

class ReadingPlanTest < ActiveSupport::TestCase
  setup do
    @plan = ReadingPlan.create!(
      slug: "test-plan",
      name: "Test Plan",
      description: "For unit tests"
    )
    @day = @plan.reading_plan_days.create!(month: 1, day: 1)
    @day.reading_plan_passages.create!(
      slot: 1, position: 0, book: "Genesis", start_chapter: 1, end_chapter: 2
    )
    @day.reading_plan_passages.create!(
      slot: 2, position: 0, book: "Psalms", start_chapter: 1, end_chapter: 2
    )
    @day.reading_plan_passages.create!(
      slot: 3, position: 0, book: "Matthew", start_chapter: 1, end_chapter: 2
    )
  end

  test "day_for returns the matching month and day" do
    found = @plan.day_for(Date.new(2026, 1, 1))

    assert_equal @day, found
    assert_equal ["Genesis 1–2", "Psalms 1–2", "Matthew 1–2"], found.reading_plan_passages.map(&:display_label)
  end

  test "day_for returns nil when no day exists (e.g. Feb 29)" do
    assert_nil @plan.day_for(Date.new(2024, 2, 29))
  end

  test "day_for is year-independent" do
    assert_equal @day, @plan.day_for(Date.new(1999, 1, 1))
    assert_equal @day, @plan.day_for(Date.new(2030, 1, 1))
  end
end
