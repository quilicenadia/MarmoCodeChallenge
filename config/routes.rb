Rails.application.routes.draw do
  # Songs scoped to artist; feature is a member action (not full Song CRUD).
  resources :artists do
    resources :songs, only: %i[new create destroy] do
      member { patch :feature }
    end
  end

  root "artists#index"
end
