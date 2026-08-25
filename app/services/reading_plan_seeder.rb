class ReadingPlanSeeder
  DEFAULT_PATH = Rails.root.join("db/data/reading_plans/bible_companion.yml")

  def self.seed!(path: DEFAULT_PATH)
    new(path).seed!
  end

  def initialize(path)
    @path = Pathname(path)
  end

  def seed!
    data = YAML.safe_load(@path.read, permitted_classes: [], aliases: false)
    raise ArgumentError, "Missing reading plan data in #{@path}" if data.blank?

    ActiveRecord::Base.transaction do
      plan = ReadingPlan.find_or_initialize_by(slug: data.fetch("slug"))
      plan.name = data.fetch("name")
      plan.description = data["description"]
      plan.save!

      existing_day_ids = plan.reading_plan_days.pluck(:id)
      ReadingPlanPassage.where(reading_plan_day_id: existing_day_ids).delete_all if existing_day_ids.any?
      plan.reading_plan_days.delete_all

      data.fetch("days").each do |day_data|
        day = plan.reading_plan_days.create!(
          month: day_data.fetch("month"),
          day: day_data.fetch("day")
        )

        day_data.fetch("readings").each do |reading|
          slot = reading.fetch("slot")
          reading.fetch("passages").each_with_index do |passage, index|
            day.reading_plan_passages.create!(
              slot: slot,
              position: index,
              book: passage.fetch("book"),
              start_chapter: passage.fetch("start_chapter"),
              end_chapter: passage.fetch("end_chapter"),
              start_verse: passage["start_verse"],
              end_verse: passage["end_verse"]
            )
          end
        end
      end

      plan
    end
  end
end
