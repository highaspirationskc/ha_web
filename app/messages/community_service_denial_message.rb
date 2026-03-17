# frozen_string_literal: true

class CommunityServiceDenialMessage < ApplicationMessage
  def initialize(record, author:, reason:)
    @record = record
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
    "Community Service Record Denied: #{@record.event}"
  end

  def body
    <<~BODY
      Your community service record has been denied.

      **Activity:** #{@record.event}
      **Date:** #{@record.event_date.strftime("%B %d, %Y")}
      **Hours:** #{@record.hours}

      **Reason for denial:**
      #{@reason}

      If you have questions, please reply to this message.
    BODY
  end

  def recipients
    [@record.mentee.user]
  end
end
