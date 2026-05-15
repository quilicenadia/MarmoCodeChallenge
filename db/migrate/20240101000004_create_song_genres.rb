class CreateSongGenres < ActiveRecord::Migration[6.1]
  def change
    create_table :song_genres do |t|
      t.references :song, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.timestamps
    end

    add_index :song_genres, %i[song_id genre_id], unique: true
  end
end
