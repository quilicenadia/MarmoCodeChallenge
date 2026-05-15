class AddFeaturedSongToArtists < ActiveRecord::Migration[6.1]
  def change
    add_reference :artists,
                  :featured_song,
                  foreign_key: { to_table: :songs, on_delete: :nullify },
                  null: true
  end
end
