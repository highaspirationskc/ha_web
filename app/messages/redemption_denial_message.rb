# frozen_string_literal: true

class RedemptionDenialMessage < ApplicationMessage
  def initialize(redemption, author:, reason:)
    @redemption = redemption
    @author_user = author
    @reason = reason
  end

  def author
    @author_user
  end

  def reply_mode
    :reply_to_sender
  end

  def subject
    "Incentive Redemption Denied: #{@redemption.incentive.name}"
  end

  def body
    <<~BODY
      Your incentive redemption has been denied.

      **Incentive:** #{@redemption.incentive.name}
      **Points:** #{@redemption.points_spent}

      **Reason for denial:**
      #{@reason}

      If you have questions, please reply to this message.
    BODY
  end

  def recipients
    [@redemption.mentee.user]
  end
end
