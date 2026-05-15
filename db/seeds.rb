return if Rails.env.test? # Request specs use non-transactional DB; seed would skew counts.

ActiveRecord::Base.transaction do
  Artist.destroy_all
  Genre.destroy_all

  artist = Artist.create!(name: "Sample Artist")

  rock = Genre.find_or_create_by!(name: "Rock")
  pop = Genre.find_or_create_by!(name: "Pop")
  folk = Genre.find_or_create_by!(name: "Folk")

  s1 = artist.songs.create!(title: "Track One", genres: [rock])
  artist.songs.create!(title: "Track Two", genres: [rock, pop])
  artist.songs.create!(title: "Track Three", genres: [folk])

  artist.mark_featured(s1)
end

puts "Seeded: #{Artist.count} artist(s), #{Song.count} song(s), #{Genre.count} genre(s)."
