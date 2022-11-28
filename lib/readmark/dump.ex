defmodule Readmark.Dump do
  @moduledoc """
  Module for importing links
  """

  alias __MODULE__.HTMLParser
  alias Readmark.Bookmarks

  def import(document) do
    {:ok, bookmarks} = HTMLParser.parse_document(document)

    Enum.map(bookmarks, &save/1)
  end

  defp save({:ok, attrs}) do
    Bookmarks.create_bookmark(attrs)
  end

  defp save({:error, msg}) do
    {:error, msg}
  end
end
