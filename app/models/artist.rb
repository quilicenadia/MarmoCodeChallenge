# Core domain: add/remove songs, at most one featured, top_genres, post-change summary.
class Artist < ApplicationRecord
  has_many :songs, dependent: :destroy
  # Schema enforces at most one featured song per artist (update replaces the previous).
  belongs_to :featured_song, class_name: "Song", optional: true

  validates :name, presence: true
  validate :featured_song_belongs_to_artist

  # Persists the song on this artist; returns summary hash (challenge shape).
  def add_song(song, featured: false)
    song.artist = self
    song.save!
    mark_featured(song) if featured
    summary
  end

  def remove_song(song)
    # Clear FK if the removed song was featured (challenge requirement).
    update!(featured_song: nil) if featured_song_id == song.id
    song.destroy!
    summary
  end

  def mark_featured(song)
    raise ArgumentError, "song does not belong to this artist" unless owns_song?(song)

    # One update replaces any previous featured row (FK lives on artist).
    update!(featured_song: song)
    summary
  end

  # Count by stored genre name; ties: alphabetical, case-insensitive (challenge).
  def top_genres(limit = 3)
    songs.joins(:genres)
         .group("genres.name")
         .count
         .sort_by { |name, count| [-count, name.downcase] }
         .first(limit)
         .map(&:first)
  end

  def song_count
    songs.count
  end

  def summary
    {
      id: id,
      name: name,
      song_count: song_count,
      top_genres: top_genres,
      featured_song_id: featured_song_id
    }
  end

  private

  # Unsaved song is not in the association yet; use artist_id before save.
  def owns_song?(song)
    return false if song.nil?

    song.persisted? ? songs.exists?(song.id) : song.artist_id == id
  end

  def featured_song_belongs_to_artist
    return if featured_song.blank?
    return if featured_song.artist_id == id

    errors.add(:featured_song, "must belong to this artist")
  end
end
