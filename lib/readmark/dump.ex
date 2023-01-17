defmodule Readmark.Dump do
  @moduledoc """
  Module for importing bookmarks.
  """

  alias __MODULE__.HTMLParser

  alias Readmark.Repo
  alias Readmark.Bookmarks

  def import(user, document) do
    document
    |> HTMLParser.parse_document()
    |> Enum.map(&save(user, &1))
  end

  def export(user) do
    Bookmarks.all_query(user_id: user.id) |> Repo.all()
  end

  defp save(user, {:ok, attrs}) do
    Bookmarks.create_bookmark(user, attrs)
  end

  defp save(_, {:error, msg}) do
    {:error, msg}
  end
end
