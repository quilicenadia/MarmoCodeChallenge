class Song < ApplicationRecord
  belongs_to :artist
  has_many :song_genres, dependent: :destroy
  has_many :genres, through: :song_genres

  validates :title, presence: true

  # Covers direct destroy (not only remove_song): clear featured if this row goes away.
  before_destroy :clear_featured_reference

  private

  def clear_featured_reference
    return unless artist&.featured_song_id == id

    # update_column skips artist callbacks/validations while this song is destroying.
    artist.update_column(:featured_song_id, nil)
  end
end
