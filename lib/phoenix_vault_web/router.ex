defmodule PhoenixVaultWeb.Router do
  use PhoenixVaultWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixVaultWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixVaultWeb do
    pipe_through :browser

    # get "/", PageController, :home
    # live "/", SnapshotsLive, :list_snapshots
    live "/snapshots", SnapshotLive.Index, :index
    live "/snapshots/new", SnapshotLive.Index, :new
    live "/snapshots/:id/edit", SnapshotLive.Index, :edit

    live "/snapshots/:id", SnapshotLive.Show, :show
    live "/snapshots/:id/show/edit", SnapshotLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixVaultWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:phoenix_vault, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PhoenixVaultWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
