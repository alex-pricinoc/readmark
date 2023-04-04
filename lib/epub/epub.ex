defmodule Epub do
  @moduledoc """
  Module for creating EPUB files.
  """

  @doc """
  Builds an EPUB document and returns the path.
  """
  def build(articles) when is_list(articles) and length(articles) > 0 do
    title = book_title(articles)

    case Epub.Native.build(title, articles) do
      {:error, error} ->
        {:error, error}

      epub ->
        {:ok, {epub, title}}
    end
  end

  defp book_title([%{title: title}]) do
    title
  end

  defp book_title(_articles) do
    Calendar.strftime(DateTime.utc_now(), "%A, %b. %-d, %Y")
  end
end
