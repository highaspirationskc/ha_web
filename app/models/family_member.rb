class FamilyMember < ApplicationRecord
  belongs_to :user
  belongs_to :related_user, class_name: "User"

  # Only parent-child family relationships are tracked here
  # Mentor/volunteer relationships are based on team membership
  enum :relationship_type, { parent: 0, guardian: 1 }

  validates :user_id, presence: true
  validates :related_user_id, presence: true
  validates :relationship_type, presence: true
  validate :cannot_relate_to_self

  private

  def cannot_relate_to_self
    errors.add(:related_user_id, "cannot be the same as user") if user_id == related_user_id
  end
end
