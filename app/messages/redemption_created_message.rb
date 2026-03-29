class RedemptionCreatedMessage < ApplicationMessage
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  def initialize(redemption)
    @redemption = redemption
    @mentee = redemption.mentee
    @incentive = redemption.incentive
    @user = @mentee.user
  end

  def author
    nil  # System message
  end

  def reply_mode
    :reply_to_sender
  end

  def support?
    true  # Goes to support inbox
  end

  def subject
    "New Redemption Request: #{@incentive.name}"
  end

  def body
    mentee_name = if @user.first_name.present? || @user.last_name.present?
      "#{@user.first_name} #{@user.last_name}".strip
    else
      @user.email
    end

    review_link = user_path(@user)

    <<~BODY
      A new incentive redemption request has been submitted.

      **Mentee:** #{mentee_name}
      **Incentive:** #{@incentive.name}
      **Description:** #{@incentive.description}
      **Point Cost:** #{@redemption.points_spent} points
      **Current Balance:** #{@mentee.total_points} points

      <a href="#{review_link}" class="text-indigo-600 hover:text-indigo-800 underline">Review this redemption</a>
    BODY
  end

  def recipients
    # All staff/admin users with manage_redemptions permission
    Authorization.users_with_permission(:manage_redemptions, :incentives).to_a
  end
end
