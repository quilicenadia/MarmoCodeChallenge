require "rails_helper"

RSpec.describe "Artists", type: :request do
  self.use_transactional_tests = false

  describe "GET /artists" do
    it "renders successfully when empty" do
      get artists_path
      expect(response).to have_http_status(:ok)
    end

    it "lists existing artists" do
      create(:artist, name: "Alpha")
      create(:artist, name: "Beta")

      get artists_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alpha", "Beta")
    end
  end

  describe "GET /artists/:id" do
    it "renders the show page" do
      artist = create(:artist, name: "Some Artist")

      get artist_path(artist)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Some Artist")
    end

    it "shows the song count, top genres and featured song" do
      artist = create(:artist, name: "Some Artist")
      song = artist.songs.create!(title: "Hit", genres: [Genre.find_or_create_by_name!("Rock")])
      artist.mark_featured(song)

      get artist_path(artist)

      expect(response.body).to include("Hit")
      expect(response.body).to include("Rock")
      expect(response.body).to include("Featured")
    end
  end

  describe "POST /artists" do
    it "creates an artist with valid params" do
      expect {
        post artists_path, params: { artist: { name: "New Artist" } }
      }.to change(Artist, :count).by(1)
      expect(response).to redirect_to(Artist.last)
    end

    it "re-renders new with invalid params" do
      post artists_path, params: { artist: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
