defmodule Readmark.EpubTest do
  use Readmark.DataCase, async: true

  import Readmark.BookmarksFixtures

  describe "build/1" do
    test "generates epub from articles" do
      article = article_fixture()

      {:ok, {epub, _title}} = Epub.build([article], %{time_zone: "Etc/UTC"})

      assert [0x50, 0x4B, 0x03, 0x04 | _rest] = epub
    end
  end
end
