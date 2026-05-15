# Thin HTTP layer; business rules live on Artist (add_song / remove_song / mark_featured).
class SongsController < ApplicationController
  before_action :set_artist
  before_action :set_song, only: %i[destroy feature]

  def new
    @song = @artist.songs.build
    @available_genres = Genre.order(:name)
  end

  def create
    @song = @artist.songs.build(song_params)
    assign_genres_to(@song)

    # Checkbox sends "1" or nil; cast avoids odd string truthiness.
    featured_flag = ActiveModel::Type::Boolean.new.cast(params[:featured])

    if @song.save
      @artist.mark_featured(@song) if featured_flag
      redirect_to @artist, notice: "Song was successfully added."
    else
      @available_genres = Genre.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @artist.remove_song(@song)
    redirect_to @artist, notice: "Song was removed."
  end

  def feature
    @artist.mark_featured(@song)
    redirect_to @artist, notice: "Featured song updated."
  rescue ArgumentError => e
    redirect_to @artist, alert: e.message
  end

  private

  def set_artist
    @artist = Artist.find(params[:artist_id])
  end

  def set_song
    @song = @artist.songs.find(params[:id])
  end

  def song_params
    params.require(:song).permit(:title)
  end

  def assign_genres_to(song)
    selected_ids = Array(params.dig(:song, :genre_ids)).reject(&:blank?)
    existing = Genre.where(id: selected_ids)

    new_genre = Genre.find_or_create_by_name!(params.dig(:song, :new_genre).to_s)

    # Replace full set; compact.uniq handles nil new_genre and duplicates.
    song.genres = (existing.to_a + [new_genre]).compact.uniq
  end
end
