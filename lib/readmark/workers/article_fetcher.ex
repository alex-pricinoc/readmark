defmodule Readmark.Workers.ArticleFetcher do
  use GenServer

  alias __MODULE__.Impl

  @name __MODULE__

  # Client

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: @name)

  @doc """
  Fetches the article for a given bookmark and updates it.
  """
  def fetch_bookmark_article(bookmark), do: GenServer.cast(@name, {:fetch, bookmark})

  @doc """
  Retrieves an existing article from the db or fetches and inserts a new one.

  Returns an `Article` struct or `nil`.
  """
  def get_or_fetch_article(url), do: GenServer.call(@name, {:fetch, url})

  # Server (callbacks)

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:fetch, bookmark}, state) do
    Impl.fetch_bookmark_article(bookmark)

    {:noreply, state}
  end

  @impl true
  def handle_call({:fetch, url}, _from, state) do
    {:reply, Impl.get_or_fetch_article(url), state}
  end
end
