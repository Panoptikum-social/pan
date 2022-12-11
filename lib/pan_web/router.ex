defmodule PanWeb.Router do
  use PanWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PanWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(PanWeb.Auth, repo: Pan.Repo)
  end

  pipeline :browser_minimal_root_layout do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PanWeb.LayoutView, :minimal_root})
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

  scope "/jsonapi", PanWeb.Api, as: :api do
    pipe_through(:json_api)

    resources("/alternate_feeds", AlternateFeedController, only: [:show])
    resources("/chapters", ChapterController, only: [:show])

    get("/categories/search", CategoryController, :search)
    resources("/categories", CategoryController, only: [:show])

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

  scope "/jsonapi/moderator", PanWeb.Api, as: :api do
    pipe_through([:json_api, :authenticate_api_moderator])
    # no moderator specific api routes defined yet
  end

  scope "/bot", PanWeb do
    pipe_through(:bot)

    get("/webhook", BotController, :webhook)
    post("/webhook", BotController, :message)
  end

  scope "/search", PanWeb do
    pipe_through([:browser])

    post("/", SearchFrontendController, :new)
    live("/:index/:term", Live.Search, :search, as: :search_frontend)
  end

  live_session :admin, on_mount: {PanWeb.Live.Auth, :admin} do
    scope "/admin", PanWeb do
      pipe_through([:browser, :authenticate_admin, :admin_layout])
      live("/", Live.Admin.Dashboard, :home, as: :dashboard)
      live("/sandbox", Live.Admin.Sandbox, :home, as: :sandbox)

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
        "/databrowser/:resource/new/:first_column/:first_id/:second_column/:second_id",
        Live.Admin.Databrowser.NewAssociation,
        :new_association,
        as: :databrowser
      )

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

  scope "/", PanWeb do
    pipe_through([:browser])

    live("/", Live.Home, :index, as: :page_frontend)
    live("/categories", Live.Category.Tree, :index, as: :category_frontend)
    live("/categories/stats", Live.Category.StatsTree, :stats, as: :category_frontend)
    live("/categories/:id", Live.Category.Show, :show, as: :category_frontend)
    live("/categories/:id/stats", Live.Category.StatsShow, :show_stats, as: :category_frontend)

    live("/categories/:id/latest_episodes", Live.Category.LatestEpisodes, :latest_episodes,
      as: :category_frontend
    )

    get("/categories/:id/categorized", CategoryFrontendController, :categorized)

    get("/podcasts/liked", PodcastFrontendController, :liked)
    get("/podcasts/popular", PodcastFrontendController, :popular)
    live("/podcasts/:id", Live.Podcast.Show, :show, as: :podcast_frontend)
    live("/podcasts", Live.Podcast.Index, :index, as: :podcast_frontend)
    get("/podcasts/:id/feeds", PodcastFrontendController, :feeds)

    get("/qrcode/:code", QRCodeFrontendController, :generate)

    live("/episodes/:id", Live.Episode.Show, :show, as: :episode_frontend)
    live("/episodes", Live.Episode.Index, :index, as: :episode_frontend)

    live("/users/new", Live.User.New, :new, as: :user_frontend)
    live("/users/:id", Live.User.Show, :show, as: :user_frontend)
    resources("/users", UserFrontendController, only: [:index])
    get("/pro_features", PageFrontendController, :pro_features)

    get("/personas/:id/grant_access", PersonaFrontendController, :grant_access)
    live("/personas", Live.Persona.Index, :index, as: :persona_frontend)
    resources("/personas", PersonaFrontendController, only: [:show])

    get("/forgot_password", UserController, :forgot_password)
    post("/request_login_link", UserController, :request_login_link)

    live("/sessions/new", Live.Session.New, :new, as: :session)
    resources("/sessions", SessionController, only: [:create, :delete])
    get("/sessions/login_via_token", SessionController, :login_via_token)
    get("/sessions/login_from_signup", SessionController, :login_from_signup)
    get("/sessions/confirm_email", SessionController, :confirm_email)

    live("/recommendations", Live.Recommendation.Index, :index, as: :recommendation_frontend)

    live("/recommendations/random", Live.Recommendation.Random, :random,
      as: :recommendation_frontend
    )

    get("/vienna-beamers", MaintenanceController, :vienna_beamers)
    get("/2016/:month/:day/:file", MaintenanceController, :blog_2016)
    get("/2017/:month/:day/:file", MaintenanceController, :blog_2017)
    live("/:pid", Live.Persona.Show, :persona, as: :persona_frontend)
  end

  scope "/", PanWeb do
    pipe_through([:browser_minimal_root_layout])

    live("/episodes/:id/player", Live.Episode.Player, :player, as: :episode_frontend)

    live("/podcasts/:id/subscribe_button", Live.Podcast.Subscribe, :subscribe_button,
      as: :podcast_frontend
    )
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
    get("/my_data", UserFrontendController, :my_data)
    delete("/delete_my_account", UserFrontendController, :delete_my_account)

    get("/edit", UserFrontendController, :edit)
    put("/update", UserFrontendController, :update)
    get("/edit_password", UserFrontendController, :edit_password)
    put("/update_password", UserFrontendController, :update_password)
    post("/go_pro", UserFrontendController, :go_pro)

    post("/personas/:id/claim", PersonaFrontendController, :claim)
    get("/personas/:id/warning", PersonaFrontendController, :warning)
    post("/personas/:id/connect", PersonaFrontendController, :connect)
    post("/personas/:id/disconnect", PersonaFrontendController, :disconnect)
    live("/personas/:id/edit", Live.Persona.Edit, :edit, as: :persona_frontend)

    resources("/opmls", OpmlFrontendController, only: [:new, :create, :index, :delete])
    get("/opmls/:id/import", OpmlFrontendController, :import)
    get("/opmls/:id/download", OpmlFrontendController, :download)

    resources("/feed_backlogs", FeedBacklogFrontendController, only: [:new, :create])

    get("/my_recommendations", RecommendationFrontendController, :my_recommendations)
    delete("/my_recommendations/delete_all", RecommendationFrontendController, :delete_all)
    resources("/recommendations", RecommendationFrontendController, only: [:create, :delete])

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

  scope "/moderator", PanWeb do
    pipe_through([:browser, :authenticate_moderator])
    get("/my_moderations", ModerationFrontendController, :my_moderations)
    live("/moderation/:id", Live.Moderation.Moderate, :moderation, as: :moderation_frontend)
    live("/moderation/:id/podcast/:podcast_id/episodes", Live.Moderation.EpisodeGrid, :episode_grid, as: :moderation_frontend)
    live("/moderation/:id/podcast/:podcast_id/feeds", Live.Moderation.FeedGrid, :feed_grid, as: :moderation_frontend)
    live("/moderation/:id/feed/:feed_id", Live.Moderation.EditFeed, :edit_feed, as: :moderation_frontend)
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

    live_dashboard("/dashboard", metrics: PanWeb.Telemetry)
    get("/episodes/remove_duplicates", EpisodeController, :remove_duplicates)

    get(
      "/episodes/remove_javascript_from_shownotes",
      EpisodeController,
      :remove_javascript_from_shownotes
    )

    get("/personas/merge_candidates", PersonaController, :merge_candidates)
    get("/personas/merge_candidate_group", PersonaController, :merge_candidate_group)
    get("/personas/merge", PersonaController, :merge)

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

    post("/feeds/:id/make_only", FeedController, :make_only)

    post("/alternate_feeds/create_from_backlog", AlternateFeedController, :create_from_backlog)

    live("/categories/merge", Live.Admin.Category.Merge, :merge, as: :category)

    get("/backlog_feeds/subscribe", FeedBacklogController, :subscribe)
    get("/backlog_feeds/subscribe50", FeedBacklogController, :subscribe50)
    get("/backlog_feeds/import_100", FeedBacklogController, :import_100)
    get("/backlog_feeds/:id/import", FeedBacklogController, :import)
    delete("/feed_backlogs/delete_all", FeedBacklogController, :delete_all)
    resources("/backlog_feeds", FeedBacklogController)

    get("/opmls/:id/import", OpmlController, :import)
    live("/opmls", Live.Admin.Opml.Index, :index, as: :opml)
    resources("/opmls", OpmlController, only: [:new, :create, :show, :update, :edit, :delete])

    resources("/invoices", InvoiceController)

    get("/images/cache_missing", ImageController, :cache_missing)
    get("/images/remove_duplicates", ImageController, :remove_duplicates)
    resources("/images", ImageController, only: [:new, :create])

    get("/podcasts/:id/pause", PodcastController, :pause)
    get("/podcasts/:id/touch", PodcastController, :touch)
    get("/podcasts/:id/contributor_import", PodcastController, :contributor_import)
    get("/podcasts/:id/delta_import", PodcastController, :delta_import)
    get("/podcasts/:id/forced_delta_import", PodcastController, :forced_delta_import)
    get("/podcasts/:id/fix_owner", PodcastController, :fix_owner)
    get("/podcasts/fix_languages", PodcastController, :fix_languages)
    get("/podcasts/:id/update_from_feed", PodcastController, :update_from_feed)
    live("/podcasts/retirement", Live.Admin.Podcast.Retirement, :retirement, as: :podcast)
    live("/podcasts/stale", Live.Admin.Podcast.Stale, :stale, as: :podcast)
    get("/podcasts/orphans", PodcastController, :orphans)
    get("/podcasts/assign_to_unsorted", PodcastController, :assign_to_unsorted)
    get("/podcasts/duplicates", PodcastController, :duplicates)
    get("/podcasts/:id/update_counters/", PodcastController, :update_counters)
    get("/podcasts/update_missing_counters", PodcastController, :update_missing_counters)
    get("/podcasts/update_all_counters", PodcastController, :update_all_counters)
    resources("/podcasts", PodcastController, only: [:delete])

    get("/search/push_missing", SearchController, :push_missing)
    get("/search/reset_all", SearchController, :reset_all)
    get("/search/delete_orphans", SearchController, :delete_orphans)
    get("/search/migrate", SearchController, :migrate)

    get("/maintenance/stats", MaintenanceController, :stats)
    get("/maintenance/catch_up_thumbnailed", MaintenanceController, :catch_up_thumbnailed)
    get("/maintenance/exception_notification", MaintenanceController, :exception_notification)
  end
end
