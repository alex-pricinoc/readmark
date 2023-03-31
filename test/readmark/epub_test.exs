defmodule Readmark.EpubTest do
  use Readmark.DataCase, async: true

  import Readmark.BookmarksFixtures

  @epub_bytes <<0x50, 0x4B, 0x03, 0x04>>

  describe "build/1" do
    test "generates epub from articels" do
      article = article_fixture()

      {:ok, {epub, delete_gen_files}} = Epub.build([article])

      epub = File.read!(epub)

      assert <<@epub_bytes, _rest::binary>> = epub

      delete_gen_files.()
    end
  end
end
