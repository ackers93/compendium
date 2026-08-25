module NavigationHelper
  def nav_daily_reading_links
    @nav_daily_reading_links ||= build_nav_daily_reading_links
  end

  private

  def build_nav_daily_reading_links
    day = nav_todays_reading_day
    (1..3).map do |slot|
      passages = day&.passages_by_slot&.dig(slot) || []
      build_nav_daily_reading_link(slot, passages)
    end
  end

  def nav_todays_reading_day
    return @nav_todays_reading_day if defined?(@nav_todays_reading_day)

    @nav_todays_reading_day = ReadingPlan.bible_companion.day_for(Date.current)
  rescue ActiveRecord::RecordNotFound
    @nav_todays_reading_day = nil
  end

  def build_nav_daily_reading_link(slot, passages)
    if passages.one?
      passage = passages.first
      { label: passage.display_label, path: passage.bible_chapter_path }
    elsif passages.many?
      {
        label: passages.map(&:display_label).join(", "),
        path: daily_readings_path(anchor: "reading-#{slot}")
      }
    else
      {
        label: ReadingPlan::SLOT_LABELS[slot],
        path: daily_readings_path(anchor: "reading-#{slot}")
      }
    end
  end
end
