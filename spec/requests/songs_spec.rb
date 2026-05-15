require "rails_helper"

RSpec.describe "Songs", type: :request do
  self.use_transactional_tests = false

  describe "GET /artists/:artist_id/songs/new" do
    it "renders the new song form" do
      artist = create(:artist)

      get new_artist_song_path(artist)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /artists/:artist_id/songs" do
    it "adds a song with an existing genre" do
      artist = create(:artist)
      rock = Genre.find_or_create_by_name!("Rock")

      expect {
        post artist_songs_path(artist), params: {
          song: { title: "Hit", genre_ids: [rock.id] }
        }
      }.to change(Song, :count).by(1)

      song = Song.last
      expect(song.title).to eq("Hit")
      expect(song.genres).to include(rock)
    end

    it "adds a song with a new genre and marks it featured" do
      artist = create(:artist)

      expect {
        post artist_songs_path(artist), params: {
          song: { title: "Solo", new_genre: "Folk" },
          featured: "1"
        }
      }.to change(Song, :count).by(1).and change(Genre, :count).by(1)

      song = Song.last
      expect(artist.reload.featured_song_id).to eq(song.id)
    end
  end

  describe "DELETE /artists/:artist_id/songs/:id" do
    it "removes the song and clears featured when it was featured" do
      artist = create(:artist)
      song = artist.songs.create!(title: "Solo")
      artist.update!(featured_song: song)

      delete artist_song_path(artist, song)

      expect(Song.where(id: song.id)).to be_empty
      expect(artist.reload.featured_song_id).to be_nil
    end
  end

  describe "PATCH /artists/:artist_id/songs/:id/feature" do
    it "marks the song as featured" do
      artist = create(:artist)
      song = artist.songs.create!(title: "Track")

      patch feature_artist_song_path(artist, song)

      expect(artist.reload.featured_song_id).to eq(song.id)
    end
  end
end
