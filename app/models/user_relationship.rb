class UserRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :related_user, class_name: "User"

  enum :relationship_type, { mentor: 0, parent: 1, guardian: 2 }

  validates :user_id, presence: true
  validates :related_user_id, presence: true
  validates :relationship_type, presence: true
  validate :cannot_relate_to_self

  private

  def cannot_relate_to_self
    errors.add(:related_user_id, "cannot be the same as user") if user_id == related_user_id
  end
end
