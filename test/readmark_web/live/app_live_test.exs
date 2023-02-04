defmodule ReadmarkWeb.AppLiveTest do
  use ReadmarkWeb.ConnCase

  import Phoenix.LiveViewTest
  import Readmark.BookmarksFixtures

  import Mox

  setup [:register_and_log_in_user]

  defp create_bookmarks(%{user: user}) do
    bookmark = bookmark_fixture(user)
    bookmark1 = bookmark_fixture(user, %{"tags" => "tag_one"})
    bookmark2 = bookmark_fixture(user, %{"tags" => "tag_one tag_two"})

    %{bookmark: bookmark, bookmark1: bookmark1, bookmark2: bookmark2}
  end

  defp create_arhived_bookmark(%{user: user}) do
    bookmark = bookmark_fixture(user, %{"folder" => :archive})

    %{bookmark: bookmark}
  end

  defp create_reading_bookmark(%{user: user}) do
    bookmark = bookmark_fixture(user, %{"folder" => :reading})

    %{bookmark: bookmark}
  end

  defp create_40_bookmarks(%{user: user}) do
    for _ <- 1..40, do: bookmark_fixture(user)

    :ok
  end

  describe "Bookmarks page" do
    @create_attrs %{"url" => "https://example.com/", "title" => "some title"}
    @update_attrs %{"title" => "updated title"}
    @invalid_attrs %{"url" => "example.com", "title" => nil}

    setup [:create_bookmarks]

    test "renders bookmarks page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/bookmarks")

      assert html =~ "Bookmarks"
    end

    # TODO: test bookmark is added to the top of the list
    test "adds new bookmark", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/bookmarks")

      assert lv
             |> element("#add-bookmark-button")
             |> render_click() =~
               "www.example.com/article.html"

      assert_patched(lv, ~p"/bookmarks/new")

      result =
        lv
        |> form("#bookmark-form", bookmark: @invalid_attrs)
        |> render_change()

      assert result =~ "is missing a scheme"
      assert result =~ "can&#39;t be blank"

      lv
      |> form("#bookmark-form", bookmark: @create_attrs)
      |> render_submit()

      html = render(lv)

      assert html =~ "some title"
      assert html =~ "Bookmark created successfully"
    end

    # TODO: test bookmark order is unchanged
    test "updates bookmark in listing", %{conn: conn, bookmark: bookmark} do
      {:ok, lv, _html} = live(conn, ~p"/bookmarks")

      assert lv |> element("#bookmarks-items-#{bookmark.id} a", "edit") |> render_click() =~
               "Edit bookmark"

      assert_patch(lv, ~p"/bookmarks/#{bookmark}/edit")

      lv
      |> form("#bookmark-form", bookmark: @update_attrs)
      |> render_submit()

      html = render(lv)

      assert html =~ "updated title"
      assert html =~ "Bookmark updated successfully"
    end

    test "archives bookmark", %{conn: conn, bookmark: bookmark} do
      {:ok, lv, _html} = live(conn, ~p"/bookmarks")

      assert lv |> element("#bookmarks-items-#{bookmark.id} a", "archive") |> render_click()
      refute has_element?(lv, "#bookmark-#{bookmark.id}")
    end

    test "filters by tags", %{conn: conn, bookmark: bookmark, bookmark1: bookmark1} do
      {:ok, lv, _html} = live(conn, ~p"/bookmarks")

      assert lv |> has_element?(~s|#bookmarks-items li:nth-of-type(3)|)

      assert lv |> has_element?("#bookmarks-items-#{bookmark.id}")

      lv |> element("#bookmarks-items-#{bookmark1.id} a", "tag_one") |> render_click()

      refute lv |> has_element?(~s|#bookmarks-items li:nth-of-type(3)|)

      refute lv |> has_element?("#bookmarks-items-#{bookmark.id}")

      lv |> element("#bookmarks-items-#{bookmark1.id} a", "tag_one") |> render_click()

      assert lv |> has_element?(~s|#bookmarks-items li:nth-of-type(3)|)

      assert lv |> has_element?("#bookmarks-items-#{bookmark.id}")
    end

    test "updates the bookmark from broadcast", %{conn: conn, bookmark: bookmark} do
      {:ok, lv, html} = live(conn, ~p"/bookmarks")

      updated_bookmark = %{bookmark | title: "some updated title"}

      refute html =~ updated_bookmark.title

      send(lv.pid, {{:bookmark, :updated}, updated_bookmark})

      assert render(lv) =~ updated_bookmark.title
    end
  end

  describe "Infinite scroll" do
    setup [:create_40_bookmarks]

    test "loads more bookmarks on scroll", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/bookmarks")

      assert lv |> has_element?(~s|#bookmarks-items li:nth-of-type(20)|)

      refute lv |> has_element?(~s|#bookmarks-items li:nth-of-type(40)|)

      render_hook(lv, :"load-more")

      assert lv |> has_element?(~s|#bookmarks-items li:nth-of-type(40)|)
    end
  end

  describe "Reading page" do
    setup :set_mox_from_context
    setup :verify_on_exit!

    @create_attrs %{"url" => "https://www.example.com/article.html"}
    @invalid_attrs %{"url" => nil}

    # valid/invalid, error summarizing
    test "adds new link", %{conn: conn} do
      ReadabilityMock
      |> expect(:summarize, 1, fn "" ->
        {:error, "something went wrong"}
      end)
      |> expect(:summarize, 1, fn "https://www.example.com/article.html" ->
        {:ok, example_article()}
      end)

      {:ok, lv, _html} = live(conn, ~p"/reading")

      assert lv
             |> element("#add-bookmark-button")
             |> render_click() =~
               "www.example.com/article.html"

      html =
        lv
        |> form("#bookmark-form", bookmark: @invalid_attrs)
        |> render_change()

      assert html =~ "can&#39;t be blank"

      html = lv |> form("#bookmark-form", bookmark: @invalid_attrs) |> render_submit()

      assert html =~ "Oops, something went wrong! Cannot save article."

      lv
      |> form("#bookmark-form", bookmark: @create_attrs)
      |> render_submit()

      html = render(lv)

      assert html =~ "Example Domain"
      assert html =~ "Link saved successfully"
    end

    setup [:create_reading_bookmark]

    test "fetches article when clicked", %{conn: conn, bookmark: bookmark} do
      ReadabilityMock
      |> expect(:summarize, 1, fn "https://www.example.com/article.html" ->
        {:ok, example_article()}
      end)

      {:ok, lv, html} = live(conn, ~p"/reading")

      refute html =~ "This domain is for use in illustrative examples in documents"

      lv |> element("#reading-items-#{bookmark.id} a", bookmark.title) |> render_click()

      assert_patch(lv, ~p"/reading/#{bookmark}")

      assert render(lv) =~ "This domain is for use in illustrative examples in documents"
    end
  end

  describe "Archive page" do
    setup [:create_arhived_bookmark]

    test "archives bookmarks", %{conn: conn, bookmark: bookmark} do
      {:ok, lv, _html} = live(conn, ~p"/archive")

      assert lv |> has_element?(~s|#archived-items-#{bookmark.id}|)

      lv |> element("#archived-items-#{bookmark.id} a", "unarchive") |> render_click()

      assert lv |> has_element?(~s|#archived-items-#{bookmark.id}[style="display: none;"]|)
    end

    test "deletes bookmarks", %{conn: conn, bookmark: bookmark} do
      {:ok, lv, _html} = live(conn, ~p"/archive")

      assert lv |> has_element?(~s|#archived-items-#{bookmark.id}|)

      lv |> element("#archived-items-#{bookmark.id} a", "delete") |> render_click()

      assert lv |> has_element?(~s|#archived-items-#{bookmark.id}[style="display: none;"]|)
    end
  end
end
