class MessageRecipient < ApplicationRecord
  belongs_to :message
  belongs_to :recipient, class_name: "User"

  scope :unread, -> { where(is_read: false) }
  scope :read, -> { where(is_read: true) }
  scope :archived, -> { where(archived: true) }
  scope :not_archived, -> { where(archived: false) }

  def mark_as_read!
    update!(is_read: true)
  end

  def archive!
    update!(archived: true)
  end

  def unarchive!
    update!(archived: false)
  end
end
