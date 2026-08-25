require "test_helper"

class ReadingPlanPassageTest < ActiveSupport::TestCase
  setup do
    plan = ReadingPlan.create!(slug: "passage-test", name: "Passage Test")
    @day = plan.reading_plan_days.create!(month: 3, day: 9)
  end

  test "display_label includes verse bounds when present" do
    passage = @day.reading_plan_passages.create!(
      slot: 2,
      position: 0,
      book: "Psalms",
      start_chapter: 119,
      end_chapter: 119,
      start_verse: 1,
      end_verse: 40
    )

    assert_equal "Psalms 119:1–40", passage.display_label
    assert_equal [119], passage.chapters
  end

  test "chapters expands inclusive ranges" do
    passage = @day.reading_plan_passages.create!(
      slot: 1,
      position: 0,
      book: "Genesis",
      start_chapter: 1,
      end_chapter: 3
    )

    assert_equal [1, 2, 3], passage.chapters
    assert_equal "Genesis 1–3", passage.display_label
    assert_equal "/bible_verses/Genesis/1", passage.bible_chapter_path
  end
end
