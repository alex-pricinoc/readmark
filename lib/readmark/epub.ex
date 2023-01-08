defmodule Readmark.Epub do
  @moduledoc """
  Module for creating EPUB files
  """
  import __MODULE__.Utils

  require Logger

  alias Readmark.Cldr
  alias Readmark.Bookmarks.Article

  @doc "Generate epub from articles."
  @spec build(articles :: [Article.t()]) :: {path :: String.t(), remove_generated_files :: fun()}
  def build(articles) do
    config = %{
      dir: dest_folder(),
      label: book_label()
    }

    articles
    |> convert_article_pages(config)
    |> to_epub(config)
  end

  defp convert_article_pages(articles, config) do
    articles
    |> Enum.with_index()
    |> Enum.map(&Task.async(fn -> to_xhtml(&1, config) end))
    |> Enum.map(&Task.await(&1, 10000))
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
        {"img", [{"src", download_image(src, dest)} | attrs]}

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

        {:error, error} ->
          Logger.warning("Unable to download image #{inspect(error)}")
          ""
      end
    end
  end

  defp dest_folder, do: Path.join([System.tmp_dir!(), "readmark", BUPE.Util.uuid4()])
  defp book_label, do: Cldr.DateTime.to_string!(DateTime.utc_now(), format: "EEEE, MMM. d, y")
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
