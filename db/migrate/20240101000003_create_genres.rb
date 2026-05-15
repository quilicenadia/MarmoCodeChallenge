class CreateGenres < ActiveRecord::Migration[6.1]
  def change
    create_table :genres do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :genres, "LOWER(name)", unique: true, name: "index_genres_on_lower_name"
  end
end
