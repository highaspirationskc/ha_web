# frozen_string_literal: true

class RedemptionApprovalMessage < ApplicationMessage
  def initialize(redemption, author:, message_text:)
    @redemption = redemption
    @author_user = author
    @message_text = message_text
  end

  def author
    @author_user
  end

  def reply_mode
    :reply_to_sender
  end

  def subject
    "Incentive Redeemed: #{@redemption.incentive.name}"
  end

  def body
    <<~BODY
      Your incentive has been redeemed!

      **Incentive:** #{@redemption.incentive.name}
      **Points:** #{@redemption.points_spent}

      #{@message_text}

      If you have questions, please reply to this message.
    BODY
  end

  def recipients
    [@redemption.mentee.user]
  end
end
