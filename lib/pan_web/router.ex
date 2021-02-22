defmodule PanWeb.Router do
  use PanWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PanWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug(PanWeb.Auth, repo: Pan.Repo)
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug(PanWeb.Auth, repo: Pan.Repo)
  end

  scope "/", PanWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  scope "/", PanWeb do
    pipe_through([:browser, :unset_cookie])

    get("/sandbox", PageFrontendController, :sandbox)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PanWeb.Telemetry
    end
  end
end
