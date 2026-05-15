# Marmoset Code Challenge — Submission

A small Rails app that models **Artists**, **Songs** and **Genres**, with rules for adding/removing songs, a single optional **featured song** per artist, and a recomputed **song count** and **top 3 genres** after every change. Business logic lives in the models and is fully covered by RSpec.

## Versions

- **Ruby** 3.2.9 (see `.ruby-version`)
- **Rails** ~> 6.1.7
- **SQLite** 3 (via `sqlite3` gem ~> 1.4)
- **RSpec** ~> 6.0 with FactoryBot, Shoulda Matchers and Faker

## Setup

```bash
bundle install
bin/rails db:create db:migrate
bin/rails db:seed     # optional: 1 artist + 3 songs + 3 genres for a quick demo
```

On Windows, follow the same commands inside the project directory (PowerShell or Git Bash).

The challenge README’s generic setup mentions **Webpacker** and **yarn/npm** for a default `rails new` template. This submission **does not use Webpacker** or any JavaScript build step. Instead, a thin client-side layer is delivered through **Sprockets** with a single `app/assets/javascripts/application.js` that requires `rails-ujs` (enables `data-confirm` on destructive buttons and `data-method` on links), `turbolinks` (smoother page navigation), plus a small `flash.js` that auto-dismisses flash messages. No yarn/npm, no JS frameworks, no client-side rendering — just enough polish to keep the UX clean.

## Running the test suite

```bash
bundle exec rspec
```

Specs are organised under `spec/`:
- `spec/models/artist_spec.rb` — full coverage of `add_song`, `remove_song`, `mark_featured`, `top_genres`, `song_count`, `summary`, featured-song lifecycle (including tie-breaking and edge cases).
- `spec/models/song_spec.rb` — associations, validations, `before_destroy` clearing the featured reference.
- `spec/models/genre_spec.rb` — case-insensitive uniqueness and name normalization.
- `spec/requests/artists_spec.rb`, `spec/requests/songs_spec.rb` — smoke coverage of the UI.

## Running the app

```bash
bin/rails server
# then open http://localhost:3000
```

The UI is intentionally plain — basic ERB views with a sprinkle of JS — and lets you:
- Create / edit / delete artists (with native `confirm()` on destructive actions, via `rails-ujs`).
- Add songs to an artist (picking from existing genres, or typing a new one with autocomplete suggestions powered by a native `<datalist>`).
- Mark a song as featured or remove it.
- See the artist's **song count**, **top genres** and **featured song** on the show page.
- Flash messages fade out automatically after 3 seconds.

## Trying the flows in `rails console`

```ruby
# bin/rails console
artist = Artist.create!(name: "Some Artist")

rock = Genre.find_or_create_by_name!("Rock")
pop  = Genre.find_or_create_by_name!("Pop")

song1 = artist.add_song(Song.new(title: "Track 1", genres: [rock]))
# => { id: …, name: "Some Artist", song_count: 1, top_genres: ["Rock"], featured_song_id: nil }

artist.add_song(Song.new(title: "Track 2", genres: [rock, pop]), featured: true)
# => { …, song_count: 2, top_genres: ["Rock", "Pop"], featured_song_id: <track 2 id> }

artist.remove_song(artist.songs.find_by(title: "Track 2"))
# Featured song is gone -> featured_song_id: nil
```

## Design decisions

- **Genre is its own model** with a many-to-many to `Song` through `song_genres`. Names are normalized (title-cased, whitespace squeezed) with a case-insensitive uniqueness index `LOWER(name)` — this makes the alphabetical, case-insensitive tie-break in `top_genres` deterministic and avoids `"Rock"` vs `"rock"` duplication.
- **Featured song is a foreign key on `artists`** (`featured_song_id`). The "zero or one" invariant is enforced by the schema; "replaces any currently featured song" is a single `UPDATE`. Removing a featured song is handled in three layers:
  1. `Artist#remove_song` clears `featured_song` before destroying the song.
  2. `Song#before_destroy` clears the reference if a song is destroyed directly.
  3. The migration's foreign key uses `on_delete: :nullify` as a final DB-level safety net.
- **`song_count` and `top_genres` are computed on demand** (not denormalized columns). This keeps the data model simpler and the recalculation requirement is satisfied by definition. Performance was not a stated goal.
- **Public API on `Artist`**: `add_song(song, featured: false)`, `remove_song(song)`, `mark_featured(song)`, `top_genres(limit = 3)`, `song_count`, `summary`. They return the summary hash where it's useful (matches the "console illustration" in the challenge README).

## Project layout (relevant files)

```
app/
  models/
    artist.rb           # add_song, remove_song, mark_featured, top_genres, summary
    song.rb             # before_destroy clears featured reference
    genre.rb            # normalized name, case-insensitive uniqueness
    song_genre.rb       # join model with compound uniqueness
  controllers/
    artists_controller.rb
    songs_controller.rb # nested under artists; includes feature member action
  views/
    artists/{index,show,new,edit,_form}.html.erb
    songs/new.html.erb
  assets/
    javascripts/
      application.js    # Sprockets bundle: rails-ujs + turbolinks + require_tree
      flash.js          # auto-dismiss flash banners after 3s
    stylesheets/application.css
db/migrate/             # 5 migrations: artists, songs, genres, song_genres, featured_song_id
spec/
  models/, requests/, factories/
```
