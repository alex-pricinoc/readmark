ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Readmark.Repo, :manual)

ExUnit.configure(exclude: [:not_implemented])
