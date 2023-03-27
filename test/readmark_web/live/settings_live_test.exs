defmodule ReadmarkWeb.SettingsLiveTest do
  use ReadmarkWeb.ConnCase

  import Swoosh.TestAssertions
  import Phoenix.LiveViewTest
  import Readmark.{AccountsFixtures, BookmarksFixtures}

  alias Readmark.Accounts

  setup :set_swoosh_global

  defp create_40_bookmarks(%{user: user}) do
    for _ <- 1..40, do: bookmark_fixture(user)

    :ok
  end

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{"password" => password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/settings")

      lv |> element("a", "Change Email") |> render_click()

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      lv |> element("a", "Change Email") |> render_click()

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      lv |> element("a", "Change Email") |> render_click()

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "user" => %{"email" => user.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{"password" => password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/settings")

      lv |> element("a", "Change Password") |> render_click()

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "user" => %{
            "email" => user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      lv |> element("a", "Change Password") |> render_click()

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      lv |> element("a", "Change Password") |> render_click()

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end

  describe "upload bookmarks" do
    setup [:register_and_log_in_user]

    test "bookmarks are imported", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/settings")

      assert html =~ "Import"
      refute has_element?(lv, ~s|button[type=submit]|, "Upload")

      bookmarks =
        file_input(lv, "#upload-bookmarks-form", :bookmarks, [
          %{
            content: File.read!("test/support/fixtures/delicious.html"),
            name: "bookmarks.html",
            size: 2541,
            type: "text/html",
            last_modified: 1_674_422_321_245
          }
        ])

      render_upload(bookmarks, "bookmarks.html")

      assert has_element?(lv, ~s|button[type=submit]|, "Upload")

      html = lv |> form("#upload-bookmarks-form") |> render_submit()

      assert html =~ "Imported 9 links"
      assert html =~ "Failed to import 1 links"

      bookmarks =
        file_input(lv, "#upload-bookmarks-form", :bookmarks, [
          %{
            content: File.read!("test/support/fixtures/delicious.html"),
            name: "bookmarks.html",
            size: 2541,
            type: "text/html",
            last_modified: 1_674_422_321_245
          }
        ])

      render_upload(bookmarks, "bookmarks.html")

      assert lv |> form("#upload-bookmarks-form") |> render_submit() =~ "Imported 18 links"
    end
  end

  describe "export bookmarks" do
    setup [:register_and_log_in_user]

    setup [:create_40_bookmarks]

    test "can export bookmarks", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      assert {:error, redirect} =
               result = lv |> element("a", "Download .HTML file") |> render_click()

      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/settings/export"

      {:ok, %{resp_body: file} = _conn} = follow_redirect(result, conn)

      assert file =~ "!DOCTYPE NETSCAPE-Bookmark-file-1"
      assert file =~ "Example title"
      assert file =~ "https://www.example.com/article.html"

      assert 40 = Regex.scan(~r/Example title/, file) |> length
    end
  end

  describe "kindle preferences" do
    setup [:register_and_log_in_user]

    test "setup", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      html = lv |> element("a", "Setup your Kindle") |> render_click()

      assert html =~ "Your Kindle Email"
      assert html =~ "Personal Document Settings"
      refute html =~ "Send Now"

      html =
        lv
        |> form("#kindle_preferences_form", %{
          user: %{
            "kindle_preferences" => %{
              "is_scheduled?" => true
            }
          }
        })
        |> render_submit()

      assert html =~ "must specify an email for Kindle Automatic Delivery"

      html =
        lv
        |> form("#kindle_preferences_form", %{
          user: %{
            "kindle_email" => "invalid email"
          }
        })
        |> render_change()

      assert html =~ "must be a valid kindle email with no spaces"

      {:ok, _lv, html} =
        lv
        |> form("#kindle_preferences_form", %{
          user: %{
            "kindle_email" => "alex_4o2432cb@kindle.com",
            "kindle_preferences" => %{
              "is_scheduled?" => false
            }
          }
        })
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Updated successfully"
      assert html =~ "Send Now"
      refute html =~ "Setup your Kindle"
    end

    test "articles can be sent immediately (no unread articles)", %{conn: conn, user: user} do
      {:ok, _user} =
        Accounts.update_user_kindle_preferences(user, %{
          kindle_email: "some.email@kindle.com",
          kindle_preferences: %{articles: 1}
        })

      {:ok, lv, html} = live(conn, ~p"/settings")

      assert html =~ "Send Now"
      refute html =~ "Setup your Kindle"

      lv |> element("button", "Send Now") |> render_click()

      assert render(lv) =~ "You don&#39;t have any unread articles"
    end

    test "articles can be sent immediately (unread articles)", %{conn: conn, user: user} do
      _bookmark = bookmark_with_article_fixture(user)

      {:ok, _user} =
        Accounts.update_user_kindle_preferences(user, %{
          kindle_email: "some.email@kindle.com",
          kindle_preferences: %{articles: 1}
        })

      {:ok, lv, _html} = live(conn, ~p"/settings")

      lv |> element("button", "Send Now") |> render_click()

      assert render(lv) =~ "Your articles have been sent to your kindle"

      assert_email_sent(fn email ->
        assert %{attachments: [%{content_type: "application/epub+zip"}]} = email
      end)
    end
  end
end
