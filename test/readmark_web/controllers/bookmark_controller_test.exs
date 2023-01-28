defmodule ReadmarkWeb.BookmarkControllerTest do
  use ReadmarkWeb.ConnCase, async: false

  import Swoosh.TestAssertions

  import Mox

  import Readmark.BookmarksFixtures

  setup :set_mox_from_context

  setup :verify_on_exit!

  describe "GET /post" do
    setup [:register_and_log_in_user]

    test "bookmark is saved", %{conn: conn} do
      bookmark = valid_bookmark_attributes()

      conn = get(conn, ~p"/_/v1/post", bookmark)

      assert redirected_to(conn) =~ bookmark["url"]
    end

    test "redirects to new bookmarks page on invalid data", %{conn: conn} do
      bookmark = valid_bookmark_attributes(%{"url" => nil})
      conn = get(conn, ~p"/_/v1/post", bookmark)
      assert redirected_to(conn) =~ ~p"/bookmarks/new?#{bookmark}"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Oops, something went wrong! Please check the changes below."

      conn = get(conn, ~p"/bookmarks/new?#{bookmark}")

      response = html_response(conn, 200)
      assert response =~ bookmark["title"]
    end
  end

  describe "GET /reading" do
    setup [:register_and_log_in_user]

    setup do
      %{bookmark_attrs: valid_bookmark_attributes()}
    end

    test "article is saved", %{conn: conn, bookmark_attrs: bookmark} do
      ReadabilityMock
      |> expect(:summarize, 1, fn _ ->
        {:ok, example_article()}
      end)

      conn = get(conn, ~p"/_/v1/reading", bookmark)

      assert redirected_to(conn) =~ bookmark["url"]
    end

    test "redirects is saving fails", %{conn: conn, bookmark_attrs: bookmark} do
      ReadabilityMock
      |> expect(:summarize, 1, fn _ ->
        {:error, "something went wrong"}
      end)

      conn = get(conn, ~p"/_/v1/reading", bookmark)

      assert redirected_to(conn) =~ ~p"/reading"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Oops, something went wrong! Cannot fetch article contents."
    end
  end

  describe "GET /kindle" do
    setup [:register_and_log_in_user]

    setup do
      %{bookmark_attrs: valid_bookmark_attributes()}
    end

    test "article is sent", %{conn: conn, user: user, bookmark_attrs: bookmark} do
      ReadabilityMock
      |> expect(:summarize, 1, fn _ ->
        {:ok, example_article()}
      end)

      {:ok, _user} =
        Readmark.Accounts.update_user_kindle_preferences(user, %{
          kindle_email: "some.email@kindle.com"
        })

      conn = get(conn, ~p"/_/v1/kindle", bookmark)

      assert redirected_to(conn) =~ bookmark["url"]

      assert_email_sent(fn email ->
        assert %{attachments: [%{content_type: "application/epub+zip"}]} = email
      end)
    end

    test "redirects is feching article fails", %{conn: conn, bookmark_attrs: bookmark} do
      ReadabilityMock
      |> expect(:summarize, 1, fn _ ->
        {:error, "something went frong"}
      end)

      conn = get(conn, ~p"/_/v1/kindle", bookmark)

      assert redirected_to(conn) =~ ~p"/reading"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Oops, something went wrong! Cannot fetch article contents."
    end
  end
end
