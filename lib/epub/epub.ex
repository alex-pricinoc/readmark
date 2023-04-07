defmodule Epub do
  @moduledoc """
  Module for creating EPUB files.
  """

  @doc """
  Builds an EPUB document and returns the path.
  """
  def build(articles, time_zone) when is_list(articles) and length(articles) > 0 do
    title = book_title(articles, time_zone)

    case Epub.Native.build(title, articles) do
      {:error, error} ->
        {:error, error}

      epub ->
        {:ok, {epub, title}}
    end
  end

  defp book_title([%{title: title}], _time_zone) do
    title
  end

  defp book_title(_articles, time_zone) do
    DateTime.utc_now()
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime("%A, %b. %-d, %Y")
  end
end
