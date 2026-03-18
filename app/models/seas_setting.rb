class SeasSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key)
    find_by(key: key)&.value
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.update!(value: value)
  end

  def self.welcome_image
    image_id = get("welcome_image_id")
    Medium.find_by(id: image_id) if image_id.present?
  end
end
