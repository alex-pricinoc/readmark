defmodule Readmark.Epub do
  @moduledoc """
  Module for creating EPUB files.
  """

  require Logger

  import __MODULE__.Utils

  @doc """
  Generate epub from articles.
  """
  def build(articles) when is_list(articles) and length(articles) > 0 do
    config = %{
      title: book_title(articles),
      dir: Path.join([System.tmp_dir!(), "readmark", BUPE.Util.uuid4()])
    }

    epub =
      articles
      |> convert_article_pages(config)
      |> to_epub(generate_cover(config), config)

    delete_gen_files = fn -> File.rm_rf!(config.dir) end

    {epub, delete_gen_files}
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
    |> to_page(%{title: title})
    |> then(&File.write(item_path, &1))

    %BUPE.Item{href: item_path, description: title}
  end

  defp generate_cover(%{title: title, dir: dest}) do
    item_path = Path.join(dest, "title.xhtml")

    build_cover(title, Path.join(dest, "cover.jpg"))

    ~s|<img src="cover.jpg" alt="Logo"/>|
    |> to_page(%{title: false})
    |> then(&File.write(item_path, &1))

    %BUPE.Item{id: "cover", href: item_path}
  end

  defp to_epub(pages, cover, %{dir: dest, title: title} = _config) do
    images = Path.wildcard(Path.join(dest, "*.{jpg,png,gif,jpeg,bmp}"))

    config = %BUPE.Config{
      title: "readmark: #{title}",
      creator: "readmark",
      cover: false,
      pages: pages,
      images: [cover | images]
    }

    with {:ok, path} <- BUPE.build(config, Path.join(dest, "readmark-#{gen_reference()}.epub")) do
      to_string(path)
    end
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
