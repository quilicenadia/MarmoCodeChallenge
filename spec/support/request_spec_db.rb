# Rack must see committed rows; lock_thread avoids parallel checkout on SQLite/Windows.
RSpec.configure do |config|
  config.around(:each, type: :request) do |example|
    ActiveRecord::Base.connection_pool.lock_thread = true
    example.run
  ensure
    ActiveRecord::Base.connection_pool.lock_thread = false
    Artist.update_all(featured_song_id: nil)
    [SongGenre, Song, Artist, Genre].each(&:delete_all)
  end
end
