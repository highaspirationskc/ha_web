# frozen_string_literal: true

class PointAdjustmentMessage < ApplicationMessage
  def initialize(point_log, author:, message_text:)
    @point_log = point_log
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
    points_word = (@point_log.points >= 0) ? "Awarded" : "Deducted"
    "Points #{points_word}: #{@point_log.points.abs} points"
  end

  def body
    points_word = (@point_log.points >= 0) ? "awarded" : "deducted"
    new_total = @point_log.mentee.total_points

    <<~BODY
      Your points have been adjusted.

      **Points #{points_word}:** #{@point_log.points.abs}
      **New Total:** #{new_total} points
      **Reason:** #{@point_log.reason}

      #{@message_text}

      If you have questions, please reply to this message.
    BODY
  end

  def recipients
    [@point_log.mentee.user]
  end
end
