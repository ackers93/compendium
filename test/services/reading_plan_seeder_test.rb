require "test_helper"

class ReadingPlanSeederTest < ActiveSupport::TestCase
  test "bible companion yaml has 365 days and loads idempotently" do
    path = Rails.root.join("db/data/reading_plans/bible_companion.yml")
    data = YAML.safe_load(path.read, permitted_classes: [], aliases: false)

    assert_equal "bible-companion", data["slug"]
    assert_equal 365, data["days"].size

    jan1 = data["days"].find { |d| d["month"] == 1 && d["day"] == 1 }
    assert_equal "Genesis", jan1["readings"][0]["passages"][0]["book"]
    assert_equal 1, jan1["readings"][0]["passages"][0]["start_chapter"]
    assert_equal 2, jan1["readings"][0]["passages"][0]["end_chapter"]

    plan = ReadingPlanSeeder.seed!(path: path)
    assert_equal 365, plan.reading_plan_days.count

    ReadingPlanSeeder.seed!(path: path)
    assert_equal 1, ReadingPlan.where(slug: "bible-companion").count
    assert_equal 365, ReadingPlan.bible_companion.reading_plan_days.count
  end

  test "seeds a small fixture plan" do
    path = Rails.root.join("test/fixtures/files/sample_reading_plan.yml")
    plan = ReadingPlanSeeder.seed!(path: path)

    assert_equal "sample-plan", plan.slug
    assert_equal 1, plan.reading_plan_days.count

    day = plan.day_for(Date.new(2026, 6, 15))
    assert_not_nil day
    assert_equal ["Ruth 1–2"], day.reading_plan_passages.map(&:display_label)
  end
end
