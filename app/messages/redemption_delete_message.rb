# frozen_string_literal: true

class RedemptionDeleteMessage < ApplicationMessage
  def initialize(redemption, author:, message_text:, refunded:)
    @redemption = redemption
    @author_user = author
    @message_text = message_text
    @refunded = refunded
  end

  def author
    @author_user
  end

  def reply_mode
    :reply_to_sender
  end

  def subject
    "Incentive Redemption Deleted: #{@redemption.incentive.name}"
  end

  def body
    refund_note = @refunded ? "Your #{@redemption.points_spent} points have been refunded." : "Points were not refunded."

    <<~BODY
      Your incentive redemption has been deleted.

      **Incentive:** #{@redemption.incentive.name}
      **Points:** #{@redemption.points_spent}
      #{refund_note}

      #{@message_text}

      If you have questions, please reply to this message.
    BODY
  end

  def recipients
    [@redemption.mentee.user]
  end
end
