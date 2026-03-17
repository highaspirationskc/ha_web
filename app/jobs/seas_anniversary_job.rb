class SeasAnniversaryJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current

    Mentee.joins(:user)
      .where.not(enrollment_date: nil)
      .where(users: { active: true })
      .find_each do |mentee|
        next unless anniversary_today?(mentee.enrollment_date, today)

        evaluation_year = today.year
        next if mentee.seas_evaluations.exists?(evaluation_year: evaluation_year)

        evaluation = SeasEvaluation.create!(mentee: mentee, evaluation_year: evaluation_year)
        SeasMailer.evaluation_invitation(mentee.user, evaluation).deliver_later
        evaluation.update_column(:email_sent_at, Time.current)
        SeasNotificationService.evaluation_sent(evaluation)
      end
  end

  private

  def anniversary_today?(enrollment_date, today)
    if enrollment_date.month == 2 && enrollment_date.day == 29
      target = today.leap? ? Date.new(today.year, 2, 29) : Date.new(today.year, 2, 28)
      today == target
    else
      enrollment_date.month == today.month && enrollment_date.day == today.day
    end
  end
end
