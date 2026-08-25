namespace :reading_plans do
  desc "Load reading plans from db/data/reading_plans/*.yml (idempotent)"
  task seed: :environment do
    Dir[Rails.root.join("db/data/reading_plans/*.yml")].sort.each do |path|
      plan = ReadingPlanSeeder.seed!(path: path)
      days = plan.reading_plan_days.count
      passages = ReadingPlanPassage.joins(:reading_plan_day).where(reading_plan_days: { reading_plan_id: plan.id }).count
      puts "Seeded #{plan.slug}: #{days} days, #{passages} passages"
    end
  end
end
