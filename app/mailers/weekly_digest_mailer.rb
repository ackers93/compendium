class WeeklyDigestMailer < ApplicationMailer
  def digest(user, summary:, week_start:, week_end:)
    @user = user
    @summary = summary
    @week_start = week_start
    @week_end = week_end
    @active_sections = summary.select { |section| section.count.positive? }
    @empty_sections = summary.select { |section| section.count.zero? }
    @empty_summary = empty_types_sentence(@empty_sections)
    @profile_url = edit_user_registration_url

    attachments.inline["logo.png"] = File.read(Rails.root.join("app/assets/images/logo-email.png"))

    mail(
      to: user.email,
      subject: "Compendium weekly digest (#{week_label})"
    )
  end

  private

  def week_label
    "#{@week_start.strftime('%b %-d')}–#{@week_end.strftime('%-d, %Y')}"
  end

  def empty_types_sentence(sections)
    labels = sections.map(&:label)
    return nil if labels.empty?

    listed =
      case labels.size
      when 1 then labels.first
      when 2 then labels.join(" or ")
      else "#{labels[0..-2].join(', ')}, or #{labels.last}"
      end

    "There were no #{listed} this week"
  end
end
