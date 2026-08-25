class DailyReadingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @date = parse_date(params[:date]) || Date.current
    @plan = ReadingPlan.bible_companion
    @day = @plan.day_for(@date)
    @prev_date = @date - 1
    @next_date = @date + 1
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.iso8601(value)
  rescue Date::Error, ArgumentError
    nil
  end
end
