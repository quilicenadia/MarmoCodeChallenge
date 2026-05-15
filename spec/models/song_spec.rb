require "rails_helper"

RSpec.describe Song, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:artist) }
    it { is_expected.to have_many(:song_genres).dependent(:destroy) }
    it { is_expected.to have_many(:genres).through(:song_genres) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "before_destroy callback" do
    let(:artist) { create(:artist) }
    let(:song)   { create(:song, artist: artist) }

    context "when this song is the artist's featured song" do
      before { artist.update!(featured_song: song) }

      it "clears featured_song_id on destroy" do
        expect { song.destroy! }
          .to change { artist.reload.featured_song_id }.from(song.id).to(nil)
      end
    end

    context "when this song is not featured" do
      it "does not touch featured_song_id" do
        other_song = create(:song, artist: artist)
        artist.update!(featured_song: other_song)

        expect { song.destroy! }
          .not_to change { artist.reload.featured_song_id }
      end
    end
  end
end
