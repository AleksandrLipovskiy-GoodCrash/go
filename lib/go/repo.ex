defmodule Go.Repo do
  use Ecto.Repo,
    otp_app: :go,
    adapter: Ecto.Adapters.Postgres
end
