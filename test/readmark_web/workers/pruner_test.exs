defmodule Readmark.Workers.PrunerTest do
  use Readmark.DataCase

  import Readmark.{AccountsFixtures, BookmarksFixtures}

  alias Readmark.Workers.Pruner
  alias Readmark.{Repo, Bookmarks}
  alias Bookmarks.Article

  @month 60 * 60 * 24 * 30

  describe "pruner tests" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "removes old articles" do
      article = article_fixture()

      {:ok, %{articles: 0, bookmarks: 0}} = perform_job(Pruner, %{})

      Article.changeset(article, %{
        inserted_at: DateTime.add(DateTime.now!("Etc/UTC"), -6 * @month)
      })
      |> Repo.update()

      {:ok, %{articles: 1, bookmarks: 0}} = perform_job(Pruner, %{})
    end

    test "does not remove old articles with bookmarks", %{user: user} do
      bookmark = bookmark_with_article_fixture(user)

      {:ok, %{articles: 0, bookmarks: 0}} = perform_job(Pruner, %{})

      %{articles: [article]} = bookmark

      Article.changeset(article, %{
        inserted_at: DateTime.add(DateTime.now!("Etc/UTC"), -6 * @month)
      })
      |> Repo.update()

      {:ok, %{articles: 0, bookmarks: 0}} = perform_job(Pruner, %{})

      Bookmarks.delete_bookmark(bookmark)

      {:ok, %{articles: 1, bookmarks: 0}} = perform_job(Pruner, %{})
    end

    test "removes old bookmarks", %{user: user} do
      bookmark = bookmark_fixture(user)

      {:ok, %{articles: 0, bookmarks: 0}} = perform_job(Pruner, %{})

      {:ok, bookmark} = Bookmarks.update_bookmark(bookmark, %{folder: :archive})

      {:ok, %{articles: 0, bookmarks: 0}} = perform_job(Pruner, %{})

      {:ok, _bookmark} =
        Bookmarks.update_bookmark(bookmark, %{
          updated_at: DateTime.add(DateTime.now!("Etc/UTC"), -2 * @month)
        })

      {:ok, %{articles: 0, bookmarks: 1}} = perform_job(Pruner, %{})
    end
  end
end
