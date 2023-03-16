defmodule Readmark.EpubTest do
  use Readmark.DataCase, async: true

  import Readmark.BookmarksFixtures

  @jpg_bytes <<0xFF, 0xD8, 0xFF>>
  @epub_bytes <<0x50, 0x4B, 0x03, 0x04>>

  defp unzip(binary) do
    {:ok, file_bin_list} = :zip.unzip(binary, [:memory])
    file_bin_list
  end

  describe "build/1" do
    test "generates epub from articels" do
      article = article_fixture()

      {:ok, {epub, delete_gen_files}} = Epub.build([article])

      epub = File.read!(epub)

      assert <<@epub_bytes, _rest::binary>> = epub

      delete_gen_files.()
    end

    test "cover is generated" do
      article = article_fixture()

      {:ok, {epub, delete_gen_files}} = Epub.build([article])

      content = unzip(File.read!(epub))

      {_, cover} =
        Enum.find(content, fn {name, _binary} ->
          name == 'OEBPS/cover.jpg'
        end)

      assert <<@jpg_bytes, _rest::binary>> = cover

      delete_gen_files.()
    end
  end
end
