defmodule Pan.SubscriptionView do
  use Pan.Web, :view


  def render("datatable.json", %{subscriptions: subscriptions}) do
    %{subscriptions: Enum.map(subscriptions, &subscription_json/1)}
  end


  def subscription_json(subscription) do
    %{id:            subscription.id,
      user_id:    subscription.user_id,
      user_name:  subscription.user.name,
      podcast_id:    subscription.podcast_id,
      podcast_title: subscription.podcast.title,
      actions:       datatable_actions(subscription, &subscription_path/3)}
  end
end