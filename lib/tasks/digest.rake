# frozen_string_literal: true

# Sends the weekly digest email summarizing content added in the previous calendar week.
#
# Schedule on Fly (app machines auto-stop, so in-process cron is unreliable):
#
#   fly machine run . \
#     --schedule "0 14 * * 1" \
#     --region sjc \
#     --rm \
#     --entrypoint /rails/bin/rails \
#     digest:weekly
#
# Cron is Monday 14:00 UTC (covers the previous Mon–Sun week).
namespace :digest do
  desc "Send the weekly digest email to opted-in users"
  task weekly: :environment do
    WeeklyDigestJob.perform_now
  end
end
