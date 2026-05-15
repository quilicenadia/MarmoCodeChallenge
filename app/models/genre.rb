# Canonical stored name; case-insensitive uniqueness matches top_genres tie-break.
class Genre < ApplicationRecord
  has_many :song_genres, dependent: :destroy
  has_many :songs, through: :song_genres

  before_validation :normalize_name

  validates :name, presence: true
  validate  :name_unique_case_insensitive

  # Used by the "new genre" form and factories; nil when input is blank.
  def self.find_or_create_by_name!(raw_name)
    normalized = raw_name.to_s.strip
    return nil if normalized.empty?

    where("LOWER(name) = ?", normalized.downcase).first ||
      create!(name: normalized)
  end

  private

  def normalize_name
    self.name = name.to_s.strip.squeeze(" ")
    self.name = name.split(/\s+/).map(&:capitalize).join(" ") if name.present?
  end

  def name_unique_case_insensitive
    return if name.blank?

    scope = self.class.where("LOWER(name) = ?", name.downcase)
    scope = scope.where.not(id: id) if persisted?
    errors.add(:name, "has already been taken") if scope.exists?
  end
end
