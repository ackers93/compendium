namespace :release do
  desc "Prepare database and seed reference data for deploy"
  task prepare: %w[db:prepare reading_plans:seed_if_needed]
end
