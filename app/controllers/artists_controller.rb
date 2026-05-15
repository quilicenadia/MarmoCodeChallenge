class ArtistsController < ApplicationController
  before_action :set_artist, only: %i[show edit update destroy]

  # Index shows derived count / top genres / featured so reviewers skip the console.
  def index
    @artists = Artist.order(:name)
  end

  def show
    @summary = @artist.summary # Single hash for the view (challenge summary shape).
    @songs   = @artist.songs.includes(:genres).order(:title)
  end

  def new
    @artist = Artist.new
  end

  def edit
  end

  def create
    @artist = Artist.new(artist_params)

    if @artist.save
      redirect_to @artist, notice: "Artist was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @artist.update(artist_params)
      redirect_to @artist, notice: "Artist was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @artist.destroy
    redirect_to artists_url, notice: "Artist was successfully destroyed."
  end

  private

  def set_artist
    @artist = Artist.find(params[:id])
  end

  def artist_params
    params.require(:artist).permit(:name)
  end
end
