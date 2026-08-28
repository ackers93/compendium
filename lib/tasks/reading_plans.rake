namespace :reading_plans do
  desc "Load reading plans from db/data/reading_plans/*.yml (idempotent)"
  task seed: :environment do
    seed_reading_plans(force: true)
  end

  desc "Load reading plans only when missing from the database"
  task seed_if_needed: :environment do
    seed_reading_plans(force: false)
  end

  def seed_reading_plans(force:)
    Dir[Rails.root.join("db/data/reading_plans/*.yml")].sort.each do |path|
      data = YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
      slug = data.fetch("slug")
      plan = ReadingPlan.find_by(slug: slug)

      if !force && plan&.reading_plan_days&.exists?
        puts "Skipping #{slug}: already seeded"
        next
      end

      plan = ReadingPlanSeeder.seed!(path: path)
      days = plan.reading_plan_days.count
      passages = ReadingPlanPassage.joins(:reading_plan_day).where(reading_plan_days: { reading_plan_id: plan.id }).count
      puts "Seeded #{slug}: #{days} days, #{passages} passages"
    end
  end
end
