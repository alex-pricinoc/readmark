defmodule Readmark.Epub do
  @moduledoc """
  Module for creating EPUB files
  """

  alias Readmark.Bookmarks.Article

  @doc "Generate epub from articles."
  @spec build(articles :: [Article.t()]) :: [String.t()]
  def build(articles) do
    dest = Path.join([:code.priv_dir(:readmark), "static", "books"])

    config = %{
      dir: dest,
      label: "Your digest for today"
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

    file_path = Path.join([dest, title_to_filename(title) <> ".xhtml"])
    File.write!(file_path, content)
    file_path
  end

  defp to_epub(files, %{dir: dir, label: label} = _config) do
    config = %BUPE.Config{
      title: label,
      pages: files
    }

    output_file = Path.join([dir, title_to_filename(label) <> ".epub"])
    BUPE.build(config, output_file)
    delete_generated_files(files)
    Path.relative_to_cwd(output_file)
  end

  defp delete_generated_files(files) do
    Enum.map(files, &File.rm!(&1))
  end

  defp title_to_filename(title), do: title |> String.replace(" ", "-") |> String.downcase()

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

  entities = [{?&, "&amp;"}, {?<, "&lt;"}, {?>, "&gt;"}, {?", "&quot;"}, {?', "&#39;"}]

  for {decoded, encoded} <- entities do
    defp unescape_html(<<unquote(decoded), rest::binary>>) do
      [unquote(encoded) | unescape_html(rest)]
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
