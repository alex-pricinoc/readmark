defmodule Readmark.EpubTest do
  use Readmark.DataCase, async: true

  import Readmark.BookmarksFixtures

  alias Readmark.Epub

  @jpg_bytes <<0xFF, 0xD8, 0xFF>>

  defp unzip(binary) do
    {:ok, file_bin_list} = :zip.unzip(binary, [:memory])
    file_bin_list
  end

  describe "build/1" do
    # pattern match on first 8 bytes to check file type
    test "generates epub from articels" do
      article = article_fixture()

      {epub, delete_gen_files} = Epub.build([article])

      epub_info = BUPE.parse(epub)

      assert epub_info.version == "3.0"

      delete_gen_files.()
    end

    test "cover is generated" do
      article = article_fixture()

      {epub, delete_gen_files} = Epub.build([article])

      content = unzip(File.read!(epub))

      {_, opf_template} =
        Enum.find(content, fn {name, _binary} ->
          name == 'OEBPS/content.opf'
        end)

      assert opf_template =~
               ~s|<item id="cover" href="content/title.xhtml" media-type="application/xhtml+xml"/>|

      {_, cover} =
        Enum.find(content, fn {name, _binary} ->
          name == 'OEBPS/content/cover.jpg'
        end)

      assert <<@jpg_bytes, _rest::binary>> = cover

      delete_gen_files.()
    end
  end
end
