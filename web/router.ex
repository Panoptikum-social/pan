defmodule Pan.Router do
  use Pan.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Pan.Auth, repo: Pan.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Pan do
    pipe_through :browser # Use the default browser stack

    get "/", PodcastFrontendController, :index
    resources "/podcasts", PodcastFrontendController, only: [:index, :show]
    resources "/episodes", EpisodeFrontendController, only: [:show]

    resources "/users", UserController, only: [:new, :create]
    get "/my_account", UserController, :my_show

    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end

  scope "/admin", Pan do
    pipe_through [:browser, :authenticate_admin]
    resources "/users", UserController
    resources "/podcasts", PodcastController
    resources "/languages", LanguageController
    resources "/feeds", FeedController
    resources "/alternate_feeds", AlternateFeedController
    resources "/contributors", ContributorController
    resources "/episodes", EpisodeController
    resources "/chapters", ChapterController
    resources "/enclosures", EnclosureController
    resources "/categories", CategoryController
  end
end
