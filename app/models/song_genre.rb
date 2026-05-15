# Explicit join: many genres per song without duplicate (song, genre) pairs.
class SongGenre < ApplicationRecord
  belongs_to :song
  belongs_to :genre

  validates :song_id, uniqueness: { scope: :genre_id }
end
