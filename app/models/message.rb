class Message < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :parent, class_name: "Message", optional: true

  has_many :replies, class_name: "Message", foreign_key: :parent_id, dependent: :destroy
  has_many :message_recipients, dependent: :destroy
  has_many :recipients, through: :message_recipients, source: :recipient

  # Reply mode determines who recipients can reply to
  # no_replies: recipients cannot reply
  # reply_to_sender: recipients can only reply to the sender (creates separate threads per recipient)
  # reply_to_all: recipients can reply to all recipients (single thread)
  enum :reply_mode, { no_replies: 0, reply_to_sender: 1, reply_to_all: 2 }

  validates :subject, presence: true
  validates :message, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :roots, -> { where(parent_id: nil) }

  def thread_root
    parent_id? ? parent.thread_root : self
  end

  def thread_messages
    root = thread_root
    # Get the root message and all its direct replies
    Message.where(id: root.id).or(Message.where(parent_id: root.id)).order(:created_at)
  end

  def reply?
    parent_id.present?
  end
end
