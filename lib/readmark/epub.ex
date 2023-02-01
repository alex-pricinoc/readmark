defmodule Readmark.Epub do
  @moduledoc """
  Module for creating EPUB files.
  """
  import __MODULE__.Utils

  require Logger

  alias Readmark.Bookmarks.Article

  @doc """
  Generate epub from articles.
  """
  @spec build(list(Article.t())) :: {path :: String.t(), remove_gen_files :: fun()}
  def build(articles) when is_list(articles) and length(articles) > 0 do
    config = %{
      label: book_title(articles),
      dir: Path.join([System.tmp_dir!(), "readmark", BUPE.Util.uuid4()])
    }

    articles
    |> convert_article_pages(config)
    |> to_epub(config)
  end

  defp convert_article_pages(articles, config) do
    articles
    |> Enum.with_index()
    |> Enum.map(&Task.async(fn -> to_xhtml(&1, config) end))
    |> Enum.map(&Task.await(&1, :timer.seconds(30)))
  end

  defp to_xhtml({%{article_html: html, title: title}, index}, %{dir: dest}) do
    unless File.exists?(dest), do: File.mkdir_p(dest)

    item_path = Path.join(dest, "story#{index}.xhtml")
    title = escape_html_text(title)

    html
    |> embed_images(dest)
    |> to_page(%{label: title})
    |> then(&File.write(item_path, &1))

    %BUPE.Item{href: item_path, description: title}
  end

  defp to_epub(pages, %{dir: dest, label: label}) do
    images = Path.wildcard(Path.join(dest, "*.{jpg,png,gif,jpeg,bmp}"))

    cover_path = Path.join(dest, "cover-image.jpg")

    cover_page = %BUPE.Item{
      id: "cover",
      media_type: "image/jpeg",
      properties: "cover-image",
      href: cover_path
    }

    config = %BUPE.Config{
      title: "readmark: #{label}",
      creator: "readmark",
      cover: false,
      pages: pages,
      images: [cover_page | images]
    }

    build_cover(label, cover_path)

    {:ok, path} = BUPE.build(config, Path.join(dest, "readmark-#{gen_reference()}.epub"))

    delete_gen_files = fn -> File.rm_rf!(dest) end

    {to_string(path), delete_gen_files}
  end

  # TODO: compress images to reduce size (using Image library)
  defp embed_images(html, dest) do
    html
    |> Floki.parse_document!()
    |> Floki.find_and_update("img", fn
      {"img", [{"src", src} | attrs]} ->
        {"img", [{"src", download_image(src, dest)} | attrs]}

      other ->
        other
    end)
    |> Floki.raw_html()
  end

  defp download_image(src, dest) do
    file_name = Path.basename(src)
    file_path = Path.join(dest, file_name)

    if File.exists?(file_path) do
      file_name
    else
      :get
      |> Finch.build(src)
      |> Finch.request(Readmark.Finch)
      |> case do
        {:ok, %Finch.Response{status: 200, body: body}} ->
          File.write!(file_path, body)
          file_name

        {_, error} ->
          Logger.warning("Unable to download image #{inspect(error)}")
          ""
      end
    end
  end

  defp book_title([%{title: title}]) do
    if String.length(title) > 50, do: String.slice(title, 0..47) <> "...", else: title
  end

  defp book_title([_ | _]) do
    Timex.format!(Timex.now(), "{WDfull}, {Mshort}. {D}, {YYYY}")
  end

  defp escape_html_text(string) do
    string
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  require EEx
  page = Path.expand("epub/templates/page.eex", __DIR__)
  EEx.function_from_file(:defp, :to_page, page, [:content, :config])
end
