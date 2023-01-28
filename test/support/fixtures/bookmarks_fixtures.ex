defmodule Readmark.BookmarksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Readmark.Bookmarks` context.
  """

  def valid_bookmark_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      "url" => "https://www.example.com/article.html",
      "title" => "Example title"
    })
  end

  def bookmark_fixture(user, attrs \\ %{}) do
    {:ok, bookmark} =
      attrs
      |> valid_bookmark_attributes()
      |> then(&Readmark.Bookmarks.create_bookmark(user, &1))

    bookmark
  end

  def example_article,
    do: Path.expand("example_article.json", __DIR__) |> File.read!() |> Jason.decode!()

  def article_fixture() do
    {:ok, article} = Readmark.Bookmarks.create_article(example_article())

    article
  end

  def bookmark_with_article_fixture(user) do
    article = article_fixture()

    bookmark_fixture(user, %{
      "title" => article.title,
      "articles" => [article],
      "url" => article.url,
      "folder" => :reading
    })
  end
end
