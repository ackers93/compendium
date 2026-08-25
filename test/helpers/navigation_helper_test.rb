require "test_helper"

class NavigationHelperTest < ActionView::TestCase
  include NavigationHelper

  setup do
    @plan = ReadingPlan.create!(
      slug: ReadingPlan::BIBLE_COMPANION_SLUG,
      name: "Bible Companion",
      description: "Test companion"
    )
    day = @plan.reading_plan_days.create!(month: 1, day: 1)
    day.reading_plan_passages.create!(
      slot: 1, position: 0, book: "Genesis", start_chapter: 1, end_chapter: 2
    )
    day.reading_plan_passages.create!(
      slot: 2, position: 0, book: "Psalms", start_chapter: 1, end_chapter: 2
    )
    day.reading_plan_passages.create!(
      slot: 3, position: 0, book: "Matthew", start_chapter: 1, end_chapter: 2
    )
  end

  test "nav_daily_reading_links uses today's passage labels and bible paths" do
    travel_to Date.new(2026, 1, 1) do
      links = nav_daily_reading_links

      assert_equal "Genesis 1–2", links[0][:label]
      assert_equal bible_verse_verses_path(book: "Genesis", chapter: 1), links[0][:path]

      assert_equal "Psalms 1–2", links[1][:label]
      assert_equal bible_verse_verses_path(book: "Psalms", chapter: 1), links[1][:path]

      assert_equal "Matthew 1–2", links[2][:label]
      assert_equal bible_verse_verses_path(book: "Matthew", chapter: 1), links[2][:path]
    end
  end

  test "nav_daily_reading_links falls back when no day exists" do
    travel_to Date.new(2024, 2, 29) do
      links = nav_daily_reading_links

      assert_equal ReadingPlan::SLOT_LABELS[1], links[0][:label]
      assert_equal daily_readings_path(anchor: "reading-1"), links[0][:path]
    end
  end
end
