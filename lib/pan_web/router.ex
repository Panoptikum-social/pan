defmodule PanWeb.Router do
  use PanWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PanWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(PanWeb.Auth, repo: Pan.Repo)
  end

  pipeline :json_api do
    plug(:accepts, ["json-api"])
    plug(:fetch_session)
    plug(:put_secure_browser_headers)
    plug(PanWeb.Api.Auth, repo: Pan.Repo)
  end

  pipeline :json_download do
    plug(:accepts, ["json-api"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(PanWeb.Auth, repo: Pan.Repo)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :bot do
    plug(:accepts, ["json"])
  end

  pipeline :admin_layout do
    plug(:put_layout, {PanWeb.LayoutView, :admin})
  end

  # allows us to visit `localhost:4000/sent_emails` while developing, to see sent emails
  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: PanWeb.Telemetry)
    end
  end

  scope "/jsonapi", PanWeb.Api, as: :api do
    pipe_through(:json_api)

    resources("/alternate_feeds", AlternateFeedController, only: [:show])
    resources("/chapters", ChapterController, only: [:show])

    get("/categories/search", CategoryController, :search)
    resources("/categories", CategoryController, only: [:index, :show])

    resources("/enclosures", EnclosureController, only: [:show])
    resources("/engagements", EngagementController, only: [:show])

    get("/episodes/search", EpisodeController, :search)
    resources("/episodes", EpisodeController, only: [:index, :show])

    resources("/feeds", FeedController, only: [:show])
    resources("/gigs", GigController, only: [:show])
    resources("/languages", LanguageController, only: [:index, :show])

    get("/personas/search", PersonaController, :search)
    resources("/personas", PersonaController, only: [:index, :show])

    resources("/users", UserController, only: [:index, :show, :create])

    get("/recommendations/random", RecommendationController, :random)
    resources("/recommendations", RecommendationController, only: [:index, :show])

    get("/podcasts/search", PodcastController, :search)
    get("/podcasts/most_subscribed", PodcastController, :most_subscribed)
    get("/podcasts/most_liked", PodcastController, :most_liked)
    get("/podcasts/last_updated", PodcastController, :last_updated)
    resources("/podcasts", PodcastController, only: [:index, :show])

    resources("/likes", LikeController, only: [:show])
    resources("/follows", FollowController, only: [:show])
    resources("/subscriptions", SubscriptionController, only: [:show])

    post("/login", SessionController, :login)
    post("/get_token", SessionController, :login)
  end

  scope "/jsonapi/pan", PanWeb.Api, as: :api do
    pipe_through([:json_api, :authenticate_api_user])

    post("/likes/toggle", LikeController, :toggle)
    post("/follows/toggle", FollowController, :toggle)
    post("/subscriptions/toggle", SubscriptionController, :toggle)
    post("/gigs/toggle", GigController, :toggle)

    resources("/recommendations", RecommendationController, only: [:create])
    get("/recommendations/my", RecommendationController, :my)

    get("/podcasts/:id/trigger_update", PodcastController, :trigger_update)
    get("/podcasts/:id/trigger_episode_update", PodcastController, :trigger_episode_update)

    get("/podcasts/i_follow", PodcastController, :i_follow)
    get("/podcasts/i_like", PodcastController, :i_like)
    get("/podcasts/i_subscribed", PodcastController, :i_subscribed)
    get("/podcasts/also_listened_to", PodcastController, :also_listened_to)
    get("/podcasts/also_liked", PodcastController, :also_liked)

    get("/categories/my", CategoryController, :my)
    post("/like_all_subscribed_podcasts", LikeController, :like_all_subscribed_podcasts)
    post("/follow_all_subscribed_podcasts", FollowController, :follow_all_subscribed_podcasts)

    get("/opmls/:id/import", OpmlController, :import)
    resources("/opmls", OpmlController, only: [:index, :show, :create, :delete])

    resources("/feed_backlogs", FeedBacklogController, only: [:show, :create])

    get("/users/my", UserController, :my)

    get("/messages/my", MessageController, :my)
    resources("/messages", MessageController, only: [:show])

    patch("/update_password", UserController, :update_password)
    put("/update_password", UserController, :update_password)
    patch("/update_user", UserController, :update_user)
    put("/update_user", UserController, :update_user)

    post("/personas/:id/claim", PersonaController, :claim)
    resources("/personas", PersonaController, only: [:update])

    resources("/delegations", DelegationController, only: [:show])
  end

  scope "/jsonapi/pro", PanWeb.Api, as: :api do
    pipe_through([:json_api, :authenticate_api_pro_user])

    post("/personas/:id/redirect", PersonaController, :redirect)
    post("/personas/:id/cancel_redirect", PersonaController, :cancel_redirect)
    put("/personas/:id", PersonaController, :pro_update)
    patch("/personas/:id", PersonaController, :pro_update)

    post("/delegations/toggle", DelegationController, :toggle)
  end

  scope "/api", PanWeb do
    pipe_through(:api)

    get("/categories/:id/get_podcasts", CategoryController, :get_podcasts)
  end

  scope "/bot", PanWeb do
    pipe_through(:bot)

    get("/webhook", BotController, :webhook)
    post("/webhook", BotController, :message)
  end

  scope "/search", PanWeb do
    pipe_through([:browser])

    post("/", SearchFrontendController, :new)
    get("/", SearchFrontendController, :new)
  end

  scope "/", PanWeb do
    pipe_through([:browser])

    live("/", Live.Home, :index, as: :page_frontend)
    live("/categories", Live.Category.Tree, :index, as: :category_frontend)
    live("/categories/stats", Live.Category.StatsTree, :stats, as: :category_frontend)
    live("/categories/:id", Live.Category.Show, :show, as: :category_frontend)
    live("/categories/:id/stats", Live.Category.StatsShow, :show_stats, as: :category_frontend)
    get("/categories/:id/latest_episodes", CategoryFrontendController, :latest_episodes)
    get("/categories/:id/categorized", CategoryFrontendController, :categorized)

    get("/podcasts/liked", PodcastFrontendController, :liked)
    get("/podcasts/popular", PodcastFrontendController, :popular)
    resources("/podcasts", PodcastFrontendController, only: [:index, :show])
    get("/podcasts/:id/feeds", PodcastFrontendController, :feeds)
    get("/podcasts/:id/subscribe_button", PodcastFrontendController, :subscribe_button)
    get("/qrcode/:code", QRCodeFrontendController, :generate)

    get("/episodes/iframeResizer.contentWindow.map", EpisodeFrontendController, :silence)
    resources("/episodes", EpisodeFrontendController, only: [:show, :index])
    get("/episodes/:id/player", EpisodeFrontendController, :player)

    live("/users/new", Live.User.New, :new, as: :user_frontend)
    resources("/users", UserFrontendController, only: [:show, :index, :create])
    get("/pro_features", PageFrontendController, :pro_features)

    get("/personas/datatable", PersonaFrontendController, :datatable)
    get("/personas/:id/grant_access", PersonaFrontendController, :grant_access)
    get("/personas/:id/business_card", PersonaFrontendController, :business_card)
    resources("/personas", PersonaFrontendController, only: [:show, :index])

    get("/forgot_password", UserController, :forgot_password)
    post("/request_login_link", UserController, :request_login_link)

    live("/sessions/new", Live.Session.New, :new, as: :session)
    resources("/sessions", SessionController, only: [:create, :delete])
    get("/sessions/login_via_token", SessionController, :login_via_token)
    get("/sessions/confirm_email", SessionController, :confirm_email)

    get("/recommendations/random", RecommendationFrontendController, :random)
    resources("/recommendations", RecommendationFrontendController, only: [:index])

    get("/vienna-beamers", MaintenanceController, :vienna_beamers)
    get("/2016/:month/:day/:file", MaintenanceController, :blog_2016)
    get("/2017/:month/:day/:file", MaintenanceController, :blog_2017)
    get("/:pid", PersonaFrontendController, :persona)
    get("/sandbox", PageFrontendController, :sandbox)
    get("/color-translator", PageFrontendController, :color_translator)
  end

  scope "/mydata", PanWeb do
    pipe_through([:json_download])

    get("/download", UserJsonDownloadController, :download)
  end

  scope "/pan", PanWeb do
    pipe_through([:browser, :authenticate_user])

    get("/users/payment_info", UserFrontendController, :payment_info)
    post("/users/like_all_subscribed", UserFrontendController, :like_all_subscribed)
    post("/users/follow_all_subscribed", UserFrontendController, :follow_all_subscribed)
    get("/my_podcasts", UserFrontendController, :my_podcasts)
    get("/my_profile", UserFrontendController, :my_profile)
    get("/my_messages", UserFrontendController, :my_messages)
    get("/my_data", UserFrontendController, :my_data)
    delete("/delete_my_account", UserFrontendController, :delete_my_account)

    get("/podcasts/:id/trigger_update", PodcastFrontendController, :trigger_update)

    get("/edit", UserFrontendController, :edit)
    put("/update", UserFrontendController, :update)
    get("/edit_password", UserFrontendController, :edit_password)
    put("/update_password", UserFrontendController, :update_password)
    post("/go_pro", UserFrontendController, :go_pro)

    post("/personas/:id/claim", PersonaFrontendController, :claim)
    get("/personas/:id/warning", PersonaFrontendController, :warning)
    post("/personas/:id/connect", PersonaFrontendController, :connect)
    post("/personas/:id/disconnect", PersonaFrontendController, :disconnect)
    resources("/personas", PersonaFrontendController, only: [:edit, :update])

    resources("/opmls", OpmlFrontendController, only: [:new, :create, :index, :delete])
    get("/opmls/:id/import", OpmlFrontendController, :import)
    get("/opmls/:id/download", OpmlFrontendController, :download)

    resources("/feed_backlogs", FeedBacklogFrontendController, only: [:new, :create])

    get("/my_recommendations", RecommendationFrontendController, :my_recommendations)
    delete("/my_recommendations/delete_all", RecommendationFrontendController, :delete_all)
    resources("/recommendations", RecommendationFrontendController, only: [:create, :delete])

    resources("/messages", MessageFrontendController, only: [:delete])
    delete("/messages/", MessageFrontendController, :delete_all)

    delete("/subscriptions/", SubscriptionFrontendController, :delete_all)

    delete("/follows/unfollow_all_categories", FollowFrontendController, :unfollow_all_categories)
    delete("/follows/unfollow_all_personas", FollowFrontendController, :unfollow_all_personas)
    delete("/follows/unfollow_all_podcasts", FollowFrontendController, :unfollow_all_podcasts)
    delete("/follows/unfollow_all_users", FollowFrontendController, :unfollow_all_users)

    delete("/likes/unlike_all_categories", LikeFrontendController, :unlike_all_categories)
    delete("/likes/unlike_all_chapters", LikeFrontendController, :unlike_all_chapters)
    delete("/likes/unlike_all_episodes", LikeFrontendController, :unlike_all_episodes)
    delete("/likes/unlike_all_personas", LikeFrontendController, :unlike_all_personas)
    delete("/likes/unlike_all_podcasts", LikeFrontendController, :unlike_all_podcasts)
    delete("/likes/unlike_all_users", LikeFrontendController, :unlike_all_users)

    delete("/manifestations/delete_all", ManifestationFrontendController, :delete_all)
    resources("/manifestations", ManifestationFrontendController, only: [:delete])
  end

  scope "/pro", PanWeb do
    pipe_through([:browser, :authenticate_pro])

    get("/personas/:id/toggle_delegation", PersonaFrontendController, :toggle_delegation)
    get("/personas/:id/cancel_redirect", PersonaFrontendController, :cancel_redirect)
    get("/personas/:id/redirect", PersonaFrontendController, :redirect)

    get("/invoices/:id/", InvoiceFrontendController, :download)
  end

  scope "/admin", PanWeb do
    pipe_through([:browser, :authenticate_admin, :admin_layout])
    get("/episodes/remove_duplicates", EpisodeController, :remove_duplicates)

    get(
      "/episodes/remove_javascript_from_shownotes",
      EpisodeController,
      :remove_javascript_from_shownotes
    )

    resources("/episodes", EpisodeController)

    resources("/chapters", ChapterController)
    resources("/enclosures", EnclosureController)

    get("/rss_feeds/datatable", RssFeedController, :datatable)
    resources("/rss_feeds", RssFeedController)

    get("/messages/datatable", MessageController, :datatable)
    resources("/messages", MessageController)

    get("/recommendations/datatable", RecommendationController, :datatable)
    resources("/recommendations", RecommendationController)

    get("/likes/datatable", LikeController, :datatable)
    resources("/likes", LikeController)

    get("/follows/datatable", FollowController, :datatable)
    resources("/follows", FollowController)

    get("/subscriptions/datatable", SubscriptionController, :datatable)
    resources("/subscriptions", SubscriptionController)

    get("/engagements/datatable", EngagementController, :datatable)
    resources("/engagements", EngagementController)

    get("/delegations/datatable", DelegationController, :datatable)
    resources("/delegations", DelegationController)

    get("/personas/datatable", PersonaController, :datatable)
    get("/personas/merge_candidates", PersonaController, :merge_candidates)
    get("/personas/merge_candidate_group", PersonaController, :merge_candidate_group)
    get("/personas/merge", PersonaController, :merge)
    resources("/personas", PersonaController)

    get("/languages/datatable", LanguageController, :datatable)
    resources("/languages", LanguageController)

    get("/gigs/datatable", GigController, :datatable)
    resources("/gigs", GigController)

    get("/edit_password/:id", UserController, :edit_password)
    put("/update_password/:id", UserController, :update_password)

    get(
      "/users/:user_id/category/:category_id/push_subscriptions",
      UserController,
      :push_subscriptions
    )

    get("/users/merge", UserController, :merge)
    post("/users/execute_merge", UserController, :execute_merge)
    post("/users/:id/unset_pro", UserController, :unset_pro)

    get("/users/datatable", UserController, :datatable)
    resources("/users", UserController)

    post("/feeds/:id/make_only", FeedController, :make_only)
    get("/feeds/datatable", FeedController, :datatable)
    resources("/feeds", FeedController)

    post("/alternate_feeds/create_from_backlog", AlternateFeedController, :create_from_backlog)
    resources("/alternate_feeds", AlternateFeedController)

    get("/categories/datatable", CategoryController, :datatable)
    get("/categories/assign_podcasts", CategoryController, :assign_podcasts)
    post("/categories/execute_assign", CategoryController, :execute_assign)
    get("/categories/merge", CategoryController, :merge)
    get("/categories/execute_merge", CategoryController, :execute_merge)
    resources("/categories", CategoryController)

    get("/backlog_feeds/subscribe", FeedBacklogController, :subscribe)
    get("/backlog_feeds/subscribe50", FeedBacklogController, :subscribe50)
    get("/backlog_feeds/import_100", FeedBacklogController, :import_100)
    get("/backlog_feeds/:id/import", FeedBacklogController, :import)
    delete("/feed_backlogs/delete_all", FeedBacklogController, :delete_all)
    resources("/backlog_feeds", FeedBacklogController)

    get("/opmls/datatable", OpmlController, :datatable)
    get("/opmls/:id/import", OpmlController, :import)
    resources("/opmls", OpmlController)

    resources("/invoices", InvoiceController)

    get("/images/datatable", ImageController, :datatable)
    get("/images/cache_missing", ImageController, :cache_missing)
    get("/images/remove_duplicates", ImageController, :remove_duplicates)
    resources("/images", ImageController)

    get("/podcasts/datatable", PodcastController, :datatable)
    get("/podcasts/datatable_stale", PodcastController, :datatable_stale)
    get("/podcasts/delta_import_all", PodcastController, :delta_import_all)
    get("/podcasts/:id/pause", PodcastController, :pause)
    get("/podcasts/:id/touch", PodcastController, :touch)
    get("/podcasts/:id/contributor_import", PodcastController, :contributor_import)
    get("/podcasts/:id/delta_import", PodcastController, :delta_import)
    get("/podcasts/:id/forced_delta_import", PodcastController, :forced_delta_import)
    get("/podcasts/:id/fix_owner", PodcastController, :fix_owner)
    get("/podcasts/fix_languages", PodcastController, :fix_languages)
    get("/podcasts/:id/retire", PodcastController, :retire)
    get("/podcasts/:id/update_from_feed", PodcastController, :update_from_feed)
    get("/podcasts/retirement", PodcastController, :retirement)
    get("/podcasts/stale", PodcastController, :stale)
    get("/podcasts/orphans", PodcastController, :orphans)
    get("/podcasts/assign_to_unsorted", PodcastController, :assign_to_unsorted)
    get("/podcasts/factory", PodcastController, :factory)
    get("/podcasts/duplicates", PodcastController, :duplicates)
    get("/podcasts/update_missing_counters", PodcastController, :update_missing_counters)
    resources("/podcasts", PodcastController, except: [:index, :show, :edit, :new])

    get("/manifestations/datatable", ManifestationController, :datatable)
    post("/manifestations/toggle", ManifestationController, :toggle)
    get("/manifestations/manifest", ManifestationController, :manifest)
    get("/manifestations/:id/get_by_user", ManifestationController, :get_by_user)
    get("/manifestations/:id/get_by_persona", ManifestationController, :get_by_persona)
    resources("/manifestations", ManifestationController)

    get("/search/push", SearchController, :elasticsearch_push_missing)
    get("/search/push_all", SearchController, :elasticsearch_push_all)
    get("/search/delete_orphans", SearchController, :elasticsearch_delete_orphans)

    get("/maintenance/stats", MaintenanceController, :stats)
    get("/maintenance/sandbox", MaintenanceController, :sandbox)
    get("/maintenance/update_podcast_counters", MaintenanceController, :update_podcast_counters)
    get("/maintenance/catch_up_thumbnailed", MaintenanceController, :catch_up_thumbnailed)
    get("/maintenance/exception_notification", MaintenanceController, :exception_notification)

    live("/dashboard", Live.Admin.Dashboard, :home, as: :dashboard)
    live("/databrowser/:resource", Live.Admin.Databrowser.Index, :index, as: :databrowser)

    live("/databrowser/:resource/db_indices", Live.Admin.Databrowser.DbIndex, :db_indices,
      as: :databrowser
    )

    live(
      "/databrowser/:resource/schema_definition",
      Live.Admin.Databrowser.SchemaDefinition,
      :schema_definition,
      as: :databrowser
    )

    live("/databrowser/:resource/new", Live.Admin.Databrowser.New, :new, as: :databrowser)
    live("/databrowser/:resource/:id", Live.Admin.Databrowser.Show, :show, as: :databrowser)
    live("/databrowser/:resource/:id/edit", Live.Admin.Databrowser.Edit, :edit, as: :databrowser)

    live(
      "/databrowser/:owner/:owner_id/has_many/:association",
      Live.Admin.Databrowser.HasMany,
      :has_many,
      as: :databrowser
    )

    live(
      "/databrowser/:owner/:owner_id/many_to_many/:association",
      Live.Admin.Databrowser.ManyToMany,
      :many_to_many,
      as: :databrowser
    )

    live(
      "/databrowser/show_mediating/:resource/:first_column/:first_id/:second_column/:second_id/id",
      Live.Admin.Databrowser.ShowMediating,
      :show_mediating,
      as: :databrowser
    )

    live(
      "/databrowser/edit_mediating/:resource/:first_column/:first_id/:second_column/:second_id/id",
      Live.Admin.Databrowser.EditMediating,
      :edit_mediating,
      as: :databrowser
    )
  end
end
