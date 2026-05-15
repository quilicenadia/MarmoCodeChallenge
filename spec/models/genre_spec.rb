require "rails_helper"

RSpec.describe Genre, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:song_genres).dependent(:destroy) }
    it { is_expected.to have_many(:songs).through(:song_genres) }
  end

  describe "validations" do
    subject { build(:genre, name: "Rock") }

    it { is_expected.to validate_presence_of(:name) }

    it "is invalid when another genre has the same name (case-insensitive)" do
      create(:genre, name: "Rock")
      duplicate = build(:genre, name: "rock")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "name normalization" do
    it "title-cases multi-word names" do
      genre = Genre.create!(name: "hip hop")
      expect(genre.name).to eq("Hip Hop")
    end

    it "strips and collapses whitespace" do
      genre = Genre.create!(name: "  jazz   fusion  ")
      expect(genre.name).to eq("Jazz Fusion")
    end
  end

  describe ".find_or_create_by_name!" do
    it "creates a new genre when none exists" do
      expect { Genre.find_or_create_by_name!("Metal") }.to change(Genre, :count).by(1)
    end

    it "returns the existing genre regardless of case" do
      existing = Genre.create!(name: "Folk")
      result = Genre.find_or_create_by_name!("folk")
      expect(result).to eq(existing)
    end

    it "returns nil for blank input" do
      expect(Genre.find_or_create_by_name!("   ")).to be_nil
    end
  end
end
