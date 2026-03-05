defmodule FastestMusicApi.Repo do
  use Ecto.Repo,
    otp_app: :fastest_music_api,
    adapter: Ecto.Adapters.Postgres
end
