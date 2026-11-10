Every `phx-click` (and `phx-change`, `phx-submit`) inside a `use PanWeb, :live_component` template must include `phx-target={@myself}`. Without it, Phoenix dispatches the event to the nearest parent LiveView, which has no matching `handle_event` clause → `FunctionClauseError`.

**Why:** Discovered when `SubscribeButton`'s `toggle-subscribe` event crashed in `Podcast.Show` (no clause there), while `LikeButton` and `FollowButton` worked because they already had `phx-target`. Also found missing on `load-more` in `podcast/recommendation_list.ex` and `episode/recommendation_list.ex`.

**How to apply:** When converting or writing a live component, check every `phx-click`/`phx-change`/`phx-submit` element and ensure `phx-target={@myself}` is present. When debugging a "no function clause matching handle_event" in a LiveView, check whether the event originates from a child live_component missing `phx-target`.
