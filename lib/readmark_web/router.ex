defmodule ReadmarkWeb.Router do
  use ReadmarkWeb, :router

  import ReadmarkWeb.UserAuth

  @content_security_policy Application.compile_env!(:readmark, :content_security_policy)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ReadmarkWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" => @content_security_policy,
      "permissions-policy" => "interest-cohort=()"
    }

    plug :fetch_current_user
  end

  # pipeline :api do
  #   plug :accepts, ["json"]
  # end

  # Other scopes may use custom stacks.
  # scope "/api", ReadmarkWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:readmark, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ReadmarkWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ReadmarkWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/", PageController, :home

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ReadmarkWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ReadmarkWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/settings/export", BookmarkController, :export

    live_session :require_authenticated_user,
      layout: {ReadmarkWeb.Layouts, :app},
      on_mount: [{ReadmarkWeb.UserAuth, :ensure_authenticated}, ReadmarkWeb.Sidebar] do
      live "/notes", NotesLive, :index
      live "/notes/:id", NotesLive, :show

      live "/reading", AppLive.Reading, :index
      live "/reading/new", AppLive.Reading, :new
      live "/reading/:id", AppLive.Reading, :show

      live "/bookmarks", AppLive.Bookmarks, :index
      live "/bookmarks/new", AppLive.Bookmarks, :new
      live "/bookmarks/:id/edit", AppLive.Bookmarks, :edit

      live "/archive", AppLive.Archive, :index

      live "/settings", SettingsLive, :index
      live "/settings/confirm_email/:token", SettingsLive, :confirm_email
      live "/settings/change_email", SettingsLive, :change_email
      live "/settings/change_display_name", SettingsLive, :change_display_name
      live "/settings/change_password", SettingsLive, :change_password
      live "/settings/change_kindle_preferences", SettingsLive, :change_kindle_preferences
    end

    delete "/users/delete_account", UserSessionController, :delete_account
  end

  scope "/", ReadmarkWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ReadmarkWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/_/v1/", ReadmarkWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/post", BookmarkController, :post
    get "/kindle", BookmarkController, :kindle
    get "/reading", BookmarkController, :reading
  end
end
