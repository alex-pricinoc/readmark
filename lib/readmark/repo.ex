defmodule Readmark.Repo do
  use Ecto.Repo,
    otp_app: :readmark,
    adapter: Ecto.Adapters.Postgres

  use Quarto, limit: 20
end
