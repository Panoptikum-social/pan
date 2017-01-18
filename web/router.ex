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


  scope "/api", Pan do
    pipe_through :api

    get "/categories/:id/get_podcasts", CategoryController, :get_podcasts
  end


  scope "/", Pan do
    pipe_through :browser # Use the default browser stack

    get "/", CategoryFrontendController, :index
    resources "/categories", CategoryFrontendController, only: [:index, :show]

    get "/podcasts/buttons", PodcastFrontendController, :button_index
    resources "/podcasts", PodcastFrontendController, only: [:index, :show]
    get "/podcasts/subscribe_button/:id", PodcastFrontendController, :subscribe_button

    resources "/episodes", EpisodeFrontendController, only: [:show, :index]
    get "/episodes/player/:id", EpisodeFrontendController, :player

    resources "/users", UserFrontendController, only: [:show, :index, :new, :create]
    resources "/personas", PersonaFrontendController, only: [:show, :index]

    get "/forgot_password", UserController, :forgot_password
    post "/request_login_link", UserController, :request_login_link

    resources "/sessions", SessionController, only: [:new, :create, :delete]
    get "/login_via_token", SessionController, :login_via_token
    get "/confirm_email", SessionController, :confirm_email

    post "/search", SearchFrontendController, :new
    get "/search", SearchFrontendController, :new

    get "/random", RecommendationFrontendController, :random
    resources "/recommendations", RecommendationFrontendController, only: [:index]
    get "/:pid", UserFrontendController, :persona
  end


  scope "/pan", Pan do
    pipe_through [:browser, :authenticate_user]

    post "/users/like_all_subscribed", UserFrontendController, :like_all_subscribed
    post "/users/follow_all_subscribed", UserFrontendController, :follow_all_subscribed
    get "/my_podcasts", UserFrontendController, :my_podcasts
    get "/my_profile", UserFrontendController, :my_profile
    get "/my_messages", UserFrontendController, :my_messages

    get "/edit", UserFrontendController, :edit
    put "/update", UserFrontendController, :update
    get "/edit_password", UserFrontendController, :edit_password
    put "/update_password", UserFrontendController, :update_password

    resources "/opmls", OpmlFrontendController, only: [:new, :create, :index, :delete]
    get "/opmls/import/:id", OpmlFrontendController, :import


   get "/my_recommendations", RecommendationFrontendController, :my_recommendations
   resources "/recommendations", RecommendationFrontendController, only: [:create]
  end


  scope "/admin", Pan do
    pipe_through [:browser, :authenticate_admin]
    resources "/languages", LanguageController
    resources "/contributors", ContributorController
    resources "/engagements", EngagementController
    resources "/episodes", EpisodeController
    resources "/chapters", ChapterController
    resources "/enclosures", EnclosureController
    resources "/gigs", GigController
    resources "/likes", LikeController
    resources "/follows", FollowController
    resources "/manifestations", ManifestationController
    resources "/messages", MessageController
    resources "/subscriptions", SubscriptionController
    resources "/recommendations", RecommendationController

    get "/personas/test", PersonaController, :test
    get "/personas/transfer", PersonaController, :transfer
    resources "/personas", PersonaController

    get "/users/merge", UserController, :merge
    post "/users/execute_merge", UserController, :execute_merge
    resources "/users", UserController

    post "/feeds/make_only/:id", FeedController, :make_only
    resources "/feeds", FeedController

    post "/alternate_feeds/create_from_backlog", AlternateFeedController, :create_from_backlog
    resources "/alternate_feeds", AlternateFeedController

    get "/categories/assign_podcasts", CategoryController, :assign_podcasts
    post "/categories/execute_assign", CategoryController, :execute_assign
    get "/categories/merge", CategoryController, :merge
    get "/categories/execute_merge", CategoryController, :execute_merge
    resources "/categories", CategoryController

    get "/backlog_feeds/subscribe", FeedBacklogController, :subscribe
    get "/backlog_feeds/import/:id", FeedBacklogController, :import
    resources "/backlog_feeds", FeedBacklogController

    get "/opmls/import/:id", OpmlController, :import
    resources "/opmls", OpmlController

    get "/podcasts/delta_import_all", PodcastController, :delta_import_all
    get "/podcasts/touch/:id/", PodcastController, :touch
    get "/podcasts/delta_import/:id/", PodcastController, :delta_import
    get "/podcasts/fix_owner/:id/", PodcastController, :fix_owner
    get "/podcasts/orphans/", PodcastController, :orphans
    get "/podcasts/factory/", PodcastController, :factory
    resources "/podcasts", PodcastController

    get "/maintenance/remove_duplicates", MaintenanceController, :remove_duplicates
    get "/maintenance/message_cleanup", MaintenanceController, :message_cleanup
  end
end
