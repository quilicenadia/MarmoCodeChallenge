require "rails_helper"

RSpec.describe Artist, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:songs).dependent(:destroy) }
    it { is_expected.to belong_to(:featured_song).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "#add_song" do
    let(:artist) { create(:artist) }

    it "persists the song under this artist" do
      song = build(:song, artist: nil, title: "Hello")
      expect { artist.add_song(song) }.to change { artist.songs.count }.from(0).to(1)
      expect(song.reload.artist).to eq(artist)
    end

    it "returns the updated summary hash" do
      song = build(:song, artist: nil, title: "Hello")
      result = artist.add_song(song)
      expect(result).to include(
        id: artist.id,
        name: artist.name,
        song_count: 1,
        top_genres: [],
        featured_song_id: nil
      )
    end

    it "marks the song as featured when featured: true is passed" do
      song = build(:song, artist: nil)
      artist.add_song(song, featured: true)
      expect(artist.reload.featured_song_id).to eq(song.id)
    end
  end

  describe "#remove_song" do
    let(:artist) { create(:artist) }
    let!(:song)  { create(:song, artist: artist) }

    it "deletes the song" do
      expect { artist.remove_song(song) }.to change { artist.songs.count }.from(1).to(0)
    end

    it "returns the updated summary" do
      result = artist.remove_song(song)
      expect(result[:song_count]).to eq(0)
      expect(result[:featured_song_id]).to be_nil
    end

    it "clears the featured reference when the removed song was featured" do
      artist.update!(featured_song: song)
      expect { artist.remove_song(song) }
        .to change { artist.reload.featured_song_id }.from(song.id).to(nil)
    end

    it "does not touch the featured reference when removing a different song" do
      featured = create(:song, artist: artist)
      artist.update!(featured_song: featured)

      expect { artist.remove_song(song) }
        .not_to change { artist.reload.featured_song_id }
    end
  end

  describe "#song_count" do
    let(:artist) { create(:artist) }

    it "returns 0 for an artist with no songs" do
      expect(artist.song_count).to eq(0)
    end

    it "reflects added songs" do
      create_list(:song, 3, artist: artist)
      expect(artist.song_count).to eq(3)
    end

    it "reflects removed songs" do
      songs = create_list(:song, 2, artist: artist)
      artist.remove_song(songs.first)
      expect(artist.song_count).to eq(1)
    end
  end

  describe "#summary" do
    let(:artist) { create(:artist, name: "Some Artist") }

    it "matches the documented shape" do
      song = artist.songs.create!(title: "Hit", genres: [Genre.find_or_create_by_name!("Rock")])
      artist.update!(featured_song: song)

      expect(artist.summary).to eq(
        id: artist.id,
        name: "Some Artist",
        song_count: 1,
        top_genres: ["Rock"],
        featured_song_id: song.id
      )
    end
  end

  describe "#mark_featured" do
    let(:artist) { create(:artist) }
    let(:song)   { create(:song, artist: artist) }

    it "sets featured_song to the given song" do
      expect { artist.mark_featured(song) }
        .to change { artist.reload.featured_song_id }.from(nil).to(song.id)
    end

    it "replaces a previously featured song" do
      first  = create(:song, artist: artist)
      second = create(:song, artist: artist)
      artist.mark_featured(first)

      expect { artist.mark_featured(second) }
        .to change { artist.reload.featured_song_id }.from(first.id).to(second.id)
    end

    it "raises when the song belongs to a different artist" do
      other_song = create(:song)
      expect { artist.mark_featured(other_song) }.to raise_error(ArgumentError)
    end

    it "returns the updated summary including featured_song_id" do
      result = artist.mark_featured(song)
      expect(result[:featured_song_id]).to eq(song.id)
    end
  end

  describe "featured song lifecycle" do
    let(:artist) { create(:artist) }

    it "is cleared when the featured song is destroyed directly" do
      song = create(:song, artist: artist)
      artist.update!(featured_song: song)

      expect { song.destroy! }
        .to change { artist.reload.featured_song_id }.from(song.id).to(nil)
    end

    it "is cleared via remove_song" do
      song = create(:song, artist: artist)
      artist.mark_featured(song)

      expect { artist.remove_song(song) }
        .to change { artist.reload.featured_song_id }.from(song.id).to(nil)
    end

    it "stays unset until explicitly set again after removal" do
      song = create(:song, artist: artist)
      artist.mark_featured(song)
      artist.remove_song(song)

      expect(artist.reload.featured_song_id).to be_nil
    end
  end

  describe "#top_genres" do
    let(:artist) { create(:artist) }

    def add_song_with_genres(*names)
      song = artist.songs.create!(title: "Song #{Song.count + 1}")
      names.each { |n| song.genres << Genre.find_or_create_by_name!(n) }
      song
    end

    it "returns an empty array when the artist has no songs" do
      expect(artist.top_genres).to eq([])
    end

    it "returns up to 3 genres" do
      add_song_with_genres("Rock")
      add_song_with_genres("Pop")
      add_song_with_genres("Folk")
      add_song_with_genres("Jazz")

      expect(artist.top_genres.size).to eq(3)
    end

    it "returns fewer than 3 when the artist has fewer distinct genres" do
      add_song_with_genres("Rock")
      add_song_with_genres("Pop")

      expect(artist.top_genres).to contain_exactly("Pop", "Rock")
    end

    it "orders by descending song count" do
      3.times { add_song_with_genres("Rock") }
      2.times { add_song_with_genres("Pop") }
      1.times { add_song_with_genres("Folk") }

      expect(artist.top_genres).to eq(%w[Rock Pop Folk])
    end

    it "breaks ties alphabetically (case-insensitive)" do
      add_song_with_genres("Banana")
      add_song_with_genres("apple")
      add_song_with_genres("Cherry")

      expect(artist.top_genres).to eq(%w[Apple Banana Cherry])
    end

    it "counts a song with multiple genres for each of its genres" do
      add_song_with_genres("Rock", "Pop")
      add_song_with_genres("Rock")

      counts = artist.songs.joins(:genres).group("genres.name").count
      expect(counts).to eq("Rock" => 2, "Pop" => 1)
      expect(artist.top_genres).to eq(%w[Rock Pop])
    end

    it "recalculates after a song is removed" do
      r1 = add_song_with_genres("Rock")
      add_song_with_genres("Rock")
      add_song_with_genres("Pop")

      expect(artist.top_genres).to eq(%w[Rock Pop])
      artist.remove_song(r1)
      expect(artist.top_genres).to eq(%w[Pop Rock])
    end

    it "ignores genres only attached to other artists' songs" do
      other = create(:artist)
      other.songs.create!(title: "X", genres: [Genre.find_or_create_by_name!("Metal")])

      add_song_with_genres("Rock")

      expect(artist.top_genres).to eq(["Rock"])
    end
  end
end
