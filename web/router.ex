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

  pipeline :json_api do
    plug :accepts, ["json-api"]
  end

  pipeline :bot do
    plug :accepts, ["json"]
  end


  pipeline :admin_layout do
    plug :put_layout, {Pan.LayoutView, :admin}
  end


  scope "/jsonapi", Pan do
    pipe_through :json_api

    resources "/categories", CategoryApiController, only: [:index, :show]
    resources "/languages", LanguageApiController, only: [:index, :show]
    resources "/podcasts", PodcastApiController, only: [:show]
  end


  scope "/api", Pan do
    pipe_through :api

    get "/categories/:id/get_podcasts", CategoryController, :get_podcasts
  end


  scope "/bot", Pan do
    pipe_through :bot

    get "/webhook", BotController, :webhook
    post "/webhook", BotController, :message
  end


  scope "/", Pan do
    pipe_through :browser # Use the default browser stack

    get "/", PageFrontendController, :home
    get "/categories/stats", CategoryFrontendController, :stats
    get "/categories/:id/stats", CategoryFrontendController, :show_stats
    resources "/categories", CategoryFrontendController, only: [:index, :show]

    get "/podcasts/buttons", PodcastFrontendController, :button_index
    resources "/podcasts", PodcastFrontendController, only: [:index, :show]
    get "/podcasts/:id/feeds", PodcastFrontendController, :feeds
    get "/podcasts/:id/subscribe_button", PodcastFrontendController, :subscribe_button

    resources "/episodes", EpisodeFrontendController, only: [:show, :index]
    get "/episodes/:id/player", EpisodeFrontendController, :player

    resources "/users", UserFrontendController, only: [:show, :index, :new, :create]
    get "/pro_features", PageFrontendController, :pro_features

    get "/personas/:id/grant_access", PersonaFrontendController, :grant_access
    resources "/personas", PersonaFrontendController, only: [:show, :index]

    get "/forgot_password", UserController, :forgot_password
    post "/request_login_link", UserController, :request_login_link

    resources "/sessions", SessionController, only: [:new, :create, :delete]
    get "/sessions/login_via_token", SessionController, :login_via_token
    get "/sessions/confirm_email", SessionController, :confirm_email

    post "/search", SearchFrontendController, :new
    get "/search", SearchFrontendController, :new

    get "/recommendations/random", RecommendationFrontendController, :random
    resources "/recommendations", RecommendationFrontendController, only: [:index]

    get "/vienna-beamers", MaintenanceController, :vienna_beamers
    get "/2016/:month/:day/:file", MaintenanceController, :blog_2016
    get "/2017/:month/:day/:file", MaintenanceController, :blog_2017
    get "/:pid", PersonaFrontendController, :persona
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
    post "/go_pro", UserFrontendController, :go_pro

    delete "/personas/:id/claim", PersonaFrontendController, :claim
    resources "/personas", PersonaFrontendController, only: [:edit, :update]

    resources "/opmls", OpmlFrontendController, only: [:new, :create, :index, :delete]
    get "/opmls/:id/import", OpmlFrontendController, :import

    resources "/feed_backlogs", FeedBacklogFrontendController, only: [:new, :create]

    get "/my_recommendations", RecommendationFrontendController, :my_recommendations
    resources "/recommendations", RecommendationFrontendController, only: [:create]
  end


  scope "/pro", Pan do
    pipe_through [:browser, :authenticate_pro]

    get "/users/payment_info", UserFrontendController, :payment_info

    get "/personas/:id/toggle_delegation", PersonaFrontendController, :toggle_delegation
    get "/personas/:id/cancel_redirect", PersonaFrontendController, :cancel_redirect
    get "/personas/:id/redirect", PersonaFrontendController, :redirect

    get "/invoices/:id/", InvoiceFrontendController, :download
  end


  scope "/admin", Pan do
    pipe_through [:browser, :authenticate_admin, :admin_layout]
    resources "/episodes", EpisodeController
    resources "/chapters", ChapterController
    resources "/enclosures", EnclosureController

    get "/messages/datatable", MessageController, :datatable
    resources "/messages", MessageController

    get "/recommendations/datatable", RecommendationController, :datatable
    resources "/recommendations", RecommendationController

    get "/likes/datatable", LikeController, :datatable
    resources "/likes", LikeController

    get "/follows/datatable", FollowController, :datatable
    resources "/follows", FollowController

    get "/subscriptions/datatable", SubscriptionController, :datatable
    resources "/subscriptions", SubscriptionController

    get "/engagements/datatable", EngagementController, :datatable
    resources "/engagements", EngagementController

    get "/delegations/datatable", DelegationController, :datatable
    resources "/delegations", DelegationController

    get "/personas/datatable", PersonaController, :datatable
    get "/personas/merge_candidates", PersonaController, :merge_candidates
    get "/personas/merge_candidate_group", PersonaController, :merge_candidate_group
    get "/personas/merge", PersonaController, :merge
    resources "/personas", PersonaController

    get "/languages/datatable", LanguageController, :datatable
    resources "/languages", LanguageController

    get "/gigs/datatable", GigController, :datatable
    resources "/gigs", GigController

    get  "/users/merge", UserController, :merge
    post "/users/execute_merge", UserController, :execute_merge
    post "/users/:id/unset_pro", UserController, :unset_pro

    get  "/users/datatable", UserController, :datatable
    resources "/users", UserController

    post "/feeds/:id/make_only", FeedController, :make_only
    get "/feeds/datatable", FeedController, :datatable
    resources "/feeds", FeedController

    post "/alternate_feeds/create_from_backlog", AlternateFeedController, :create_from_backlog
    resources "/alternate_feeds", AlternateFeedController

    get  "/categories/datatable", CategoryController, :datatable
    get  "/categories/assign_podcasts", CategoryController, :assign_podcasts
    post "/categories/execute_assign", CategoryController, :execute_assign
    get  "/categories/merge", CategoryController, :merge
    get  "/categories/execute_merge", CategoryController, :execute_merge
    resources "/categories", CategoryController

    get "/backlog_feeds/subscribe", FeedBacklogController, :subscribe
    get "/backlog_feeds/import_100", FeedBacklogController, :import_100
    get "/backlog_feeds/:id/import", FeedBacklogController, :import
    resources "/backlog_feeds", FeedBacklogController

    get "/opmls/datatable", OpmlController, :datatable
    get "/opmls/:id/import", OpmlController, :import
    resources "/opmls", OpmlController

    resources "/invoices", InvoiceController

    get "/podcasts/datatable", PodcastController, :datatable
    get "/podcasts/datatable_stale", PodcastController, :datatable_stale
    get "/podcasts/delta_import_all", PodcastController, :delta_import_all
    get "/podcasts/:id/pause", PodcastController, :pause
    get "/podcasts/:id/touch", PodcastController, :touch
    get "/podcasts/:id/contributor_import", PodcastController, :contributor_import
    get "/podcasts/:id/delta_import", PodcastController, :delta_import
    get "/podcasts/:id/fix_owner", PodcastController, :fix_owner
    get "/podcasts/fix_languages", PodcastController, :fix_languages
    get "/podcasts/:id/retire", PodcastController, :retire
    get "/podcasts/retirement", PodcastController, :retirement
    get "/podcasts/stale", PodcastController, :stale
    get "/podcasts/orphans", PodcastController, :orphans
    get "/podcasts/assign_to_unsorted", PodcastController, :assign_to_unsorted
    get "/podcasts/factory", PodcastController, :factory
    get "/podcasts/duplicates", PodcastController, :duplicates
    resources "/podcasts", PodcastController

    get "/manifestations/datatable", ManifestationController, :datatable
    post "/manifestations/toggle", ManifestationController, :toggle
    get "/manifestations/manifest", ManifestationController, :manifest
    get "/manifestations/:id/get_by_user", ManifestationController, :get_by_user
    get "/manifestations/:id/get_by_persona", ManifestationController, :get_by_persona
    resources "/manifestations", ManifestationController

    get "/search/:id/push", SearchController, :elasticsearch_push
    get "/search/push_all", SearchController, :elasticsearch_push_all
    get "/search/delete_orphans", SearchController, :elasticsearch_delete_orphans

    get "/maintenance/fix", MaintenanceController, :fix
  end
end
