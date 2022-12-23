defmodule Readmark.Epub do
  @moduledoc """
  Module for creating EPUB files
  """

  alias __MODULE__.Utils
  alias Readmark.Bookmarks.Article
  alias Readmark.Cldr

  @doc "Generate epub from articles."
  @spec build(articles :: [Article.t()]) :: [String.t()]
  def build(articles) do
    config = %{
      dir: Path.join([:code.priv_dir(:readmark), "static", "books"]),
      label: Cldr.DateTime.to_string!(DateTime.utc_now(), format: "EEEE, MMM. d, y")
    }

    articles
    |> convert_article_pages(config)
    |> to_epub(config)
  end

  defp convert_article_pages(articles, config) do
    articles
    |> Enum.map(&Task.async(fn -> to_xhtml(&1, config) end))
    |> Enum.map(&Task.await(&1, :infinity))
  end

  defp to_xhtml(%{article_html: html, title: title}, %{dir: dest} = _config) do
    config = %{
      label: title
    }

    content =
      html
      |> clean_code_block()
      |> to_page(config)

    unless File.exists?(dest), do: File.mkdir_p(dest)

    file_path = Path.join([dest, Ecto.UUID.generate() <> ".xhtml"])
    File.write!(file_path, content)
    %BUPE.Item{href: file_path, description: title}
  end

  defp to_epub(files, %{dir: dir, label: label} = _config) do
    id = BUPE.Util.uuid4()

    cover_name = "cover-#{id}.jpg"
    cover = BUPE.Item.from_string(Path.join([dir, cover_name]))
    Utils.build_cover(label, cover.href)

    config = %BUPE.Config{
      title: "readmark: " <> label,
      pages: files,
      creator: "readmark",
      images: [cover],
      logo: cover_name,
      cover: true
    }

    output_file = Path.join([dir, "readmark-#{id}.epub"])
    BUPE.build(config, output_file)
    delete_generated_files([cover | files])
    Path.relative_to_cwd(output_file)
  end

  defp delete_generated_files(files), do: Enum.map(files, &File.rm!(&1.href))

  defp clean_code_block(page) do
    regex = ~r/<pre><code>(.*?)<\/code><\/pre>/s
    Regex.replace(regex, page, &clean_code_block/2)
  end

  defp clean_code_block(_html, code) do
    code =
      code
      |> unescape_html()
      |> IO.iodata_to_binary()

    ~s(<pre><code>#{code}</code></pre>)
  end

  escapes = [{?<, "&lt;"}, {?>, "&gt;"}, {?&, "&amp;"}, {?", "&quot;"}, {?', "&#39;"}]

  for {match, insert} <- escapes do
    defp unescape_html(<<unquote(match), rest::binary>>) do
      [unquote(insert) | unescape_html(rest)]
    end
  end

  defp unescape_html(<<c, rest::binary>>) do
    [c | unescape_html(rest)]
  end

  defp unescape_html(<<>>) do
    []
  end

  require EEx
  page = Path.expand("epub/templates/page.eex", __DIR__)
  EEx.function_from_file(:defp, :to_page, page, [:content, :config])
end
