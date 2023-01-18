defmodule Readmark.Epub do
  @moduledoc """
  Module for creating EPUB files
  """
  import __MODULE__.Utils

  require Logger

  alias Readmark.Bookmarks.Article

  @doc """
  Generate epub from articles.
  """
  @spec build(list(Article.t()) | Article.t()) :: {path :: String.t(), remove_gen_files :: fun()}
  def build(articles) when is_list(articles) do
    config = %{
      dir: Path.join([System.tmp_dir!(), "readmark", BUPE.Util.uuid4()]),
      label: Timex.format!(Timex.now(), "{WDfull}, {Mshort}. {D}, {YYYY}")
    }

    articles
    |> convert_article_pages(config)
    |> to_epub(config)
  end

  def build(%Article{} = article) do
    build([article])
  end

  defp convert_article_pages(articles, config) do
    articles
    |> Enum.with_index()
    |> Enum.map(&Task.async(fn -> to_xhtml(&1, config) end))
    |> Enum.map(&Task.await(&1, :timer.seconds(30)))
  end

  defp to_xhtml({%Article{article_html: html, title: title}, index}, %{dir: dest}) do
    unless File.exists?(dest), do: File.mkdir_p(dest)

    file_path = Path.join(dest, "section#{pad_leading(index)}.xhtml")
    title = encode(title)

    html
    |> embed_images(dest)
    |> to_page(%{label: title})
    |> then(&File.write(file_path, &1))

    %BUPE.Item{href: file_path, description: title}
  end

  defp to_epub(pages, %{dir: dest, label: label}) do
    build_cover(label, Path.join(dest, "cover.jpg"))
    images = Path.wildcard(Path.join(dest, "*.{jpg,png,gif,jpeg,bmp}"))

    config = %BUPE.Config{
      title: "readmark: #{label}",
      creator: "readmark",
      logo: "cover.jpg",
      cover: true,
      pages: pages,
      images: images
    }

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
        image = download_image(src, dest)
        Process.sleep(500)
        {"img", [{"src", image} | attrs]}

      other ->
        other
    end)
    |> Floki.raw_html()
  end

  def download_image(src, dest) do
    file_name = Path.basename(src)
    file_path = Path.join(dest, file_name)

    if File.exists?(file_path) do
      file_name
    else
      :get
      |> Finch.build(src)
      |> Finch.request(Readmark.Finch)
      |> case do
        # TODO: maybe handle potential redirects
        {:ok, %Finch.Response{status: 200, body: body}} ->
          File.write!(file_path, body)
          file_name

        error ->
          Logger.warning("Unable to download image #{inspect(error)}")
          ""
      end
    end
  end

  defp pad_leading(index), do: String.pad_leading(to_string(index), 4, "0")

  def encode(string) do
    String.replace(string, ["'", "\"", "&", "<", ">"], fn
      "'" -> "&#39;"
      "\"" -> "&quot;"
      "&" -> "&amp;"
      "<" -> "&lt;"
      ">" -> "&gt;"
    end)
  end

  require EEx
  page = Path.expand("epub/templates/page.eex", __DIR__)
  EEx.function_from_file(:defp, :to_page, page, [:content, :config])
end
