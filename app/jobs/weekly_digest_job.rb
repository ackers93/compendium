class WeeklyDigestJob < ApplicationJob
  queue_as :default

  def perform(now: Time.zone.now)
    range = WeeklyDigestCollector.previous_week_range(now)
    summary = WeeklyDigestCollector.call(range: range)

    User.where(weekly_digest_enabled: true).find_each do |user|
      WeeklyDigestMailer.digest(
        user,
        summary: summary,
        week_start: range.begin,
        week_end: range.end
      ).deliver_now
    end
  end
end
