defmodule Readmark.ArticleFetcher.Server do
  use GenServer

  alias Readmark.ArticleFetcher.Impl

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
