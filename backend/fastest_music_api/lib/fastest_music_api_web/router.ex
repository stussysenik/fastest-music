defmodule FastestMusicApiWeb.Router do
  use FastestMusicApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["*"]
  end

  scope "/api", FastestMusicApiWeb do
    pipe_through :api

    get "/search", SearchController, :index
    get "/albums/by-name/artwork", AlbumController, :artwork_by_name
    get "/albums/:id", AlbumController, :show
    post "/artwork/batch", ArtworkController, :batch
    get "/health", HealthController, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:fastest_music_api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: FastestMusicApiWeb.Telemetry
    end
  end
end
