defmodule Readmark.ArticleFetcher do
  alias Readmark.Bookmarks.Bookmark

  @server Readmark.ArticleFetcher.Server

  def start_link() do
    GenServer.start_link(@server, nil, name: @server)
  end

  @doc """
  Fetches the article for a given bookmark and updates it.

  """
  def fetch_bookmark_article(%Bookmark{} = bookmark) do
    GenServer.cast(@server, {:fetch, bookmark})
  end

  @doc """
  Retrieves an existing article from the db or fetches and inserts a new one.

  Returns an `Article` struct or `nil`.
  """
  def get_or_fetch_article(url) when is_binary(url) do
    GenServer.call(@server, {:fetch, url})
  end
end
