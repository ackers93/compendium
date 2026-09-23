module BrowserTimeZone
  extend ActiveSupport::Concern

  COOKIE_NAME = :time_zone

  included do
    around_action :use_browser_time_zone
  end

  private

  def use_browser_time_zone(&block)
    Time.use_zone(resolved_browser_time_zone, &block)
  end

  def resolved_browser_time_zone
    name = cookies[COOKIE_NAME].to_s.strip
    return Time.zone_default if name.blank?

    Time.find_zone(name) || Time.zone_default
  end
end
