defmodule Epub do
  @moduledoc """
  Module for creating EPUB files.
  """

  @doc """
  Builds an EPUB document and returns the path.
  """
  def build(articles) when is_list(articles) and length(articles) > 0 do
    options = %Epub.Native.EpubOptions{
      title: book_title(articles),
      dir: Path.join([System.tmp_dir!(), "readmark", Ecto.UUID.generate()])
    }

    delete_gen_files = fn -> File.rm_rf!(options.dir) end

    File.mkdir_p(options.dir)

    Epub.Cover.build_cover(options.title, Path.join(options.dir, "cover.jpg"))

    case Epub.Native.build(articles, options) do
      {:error, error} ->
        delete_gen_files.()

        {:error, error}

      epub ->
        {:ok, {epub, delete_gen_files}}
    end
  end

  defp book_title([%{title: title}]) do
    String.slice(title, 0..50)
  end

  defp book_title(_articles) do
    Timex.format!(Timex.now(), "{WDfull}, {Mshort}. {D}, {YYYY}")
  end
end
