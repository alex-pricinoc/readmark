defmodule Readmark.Repo do
  use Ecto.Repo,
    otp_app: :readmark,
    adapter: Ecto.Adapters.Postgres
end
