class FamilyMember < ApplicationRecord
  belongs_to :guardian
  belongs_to :mentee

  enum :relationship_type, {
    parent: "parent",
    grandparent: "grandparent",
    aunt_uncle: "aunt_uncle",
    sibling: "sibling",
    other: "other"
  }

  validates :relationship_type, presence: true
  validates :guardian_id, uniqueness: { scope: :mentee_id }
end
