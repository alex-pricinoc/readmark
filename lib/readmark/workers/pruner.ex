defmodule Readmark.Workers.Pruner do
  use Oban.Worker,
    queue: :pruning,
    unique: [period: 60],
    tags: ["deletion", "pruning"]

  alias Readmark.{Repo, Bookmarks}

  @impl Oban.Worker
  def perform(_) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:bookmarks, fn _, _ -> Bookmarks.prune_archived_bookmarks() end)
    |> Ecto.Multi.run(:articles, fn _, _ -> Bookmarks.prune_archived_articles() end)
    |> Repo.transaction()
    |> case do
      {:ok, result} -> {:ok, result}
      {:error, _, error, _} -> {:error, error}
    end
  end
end
