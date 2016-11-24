defmodule Pan.CategoryFrontendView do
  use Pan.Web, :view
  use Pan.Web, :controller
  alias Pan.Category


  def panel_cycle(counter) do
    Enum.at(["panel-default", "panel-info", "panel-danger",
             "panel-warning", "panel-primary", "panel-success"], rem(counter, 6))
  end


  def btn_cycle(counter) do
    Enum.at(["btn-default", "btn-info", "btn-danger",
             "btn-warning", "btn-primary", "btn-success"], rem(counter, 6))
  end


  def color_cycle(counter) do
    Enum.at(["666", "fff", "fff",
             "fff", "fff", "fff"], rem(counter, 6))
  end


  def latest_podcasts do
    Repo.all(from p in Pan.Podcast, order_by: [desc: :inserted_at],
                                    limit: 5)
  end


  def latest_episodes do
    Repo.all(from e in Pan.Episode, order_by: [desc: :publishing_date],
                                    limit: 5)
    |> Repo.preload(:podcast)
  end


  def list_group_item_cycle(counter) do
    Enum.at(["list-group-item-info", "list-group-item-danger",
             "list-group-item-warning", "list-group-item-primary", "list-group-item-success"], rem(counter, 5))
  end


  def like_or_unlike(user_id, category_id) do
    case Pan.Repo.get_by(Pan.Like, enjoyer_id: user_id,
                                   category_id: category_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "category",
                                    event: "like",
                                    action: "like",
                                    id: category_id] do
          [Category.likes(category_id), " ", fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "category",
                                    event: "like",
                                    action: "unlike" ,
                                    id: category_id] do
          [Category.likes(category_id), " ", fa_icon("heart"), " Unlike"]
        end
    end
  end

  def render("like_button.html", %{user_id: user_id, category_id: category_id}) do
    like_or_unlike(user_id, category_id)
  end


  def follow_or_unfollow(user_id, category_id) do
    case Pan.Repo.get_by(Pan.Follow, follower_id: user_id,
                                     category_id: category_id) do
      nil ->
        content_tag :button, class: "btn btn-primary",
                             data: [type: "category",
                                    event: "follow",
                                    action: "follow",
                                    id: category_id] do
          [Category.follows(category_id), " ", fa_icon("commenting-o"), " Follow"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "category",
                                    event: "follow",
                                    action: "unfollow" ,
                                    id: category_id] do
          [Category.follows(category_id), " ", fa_icon("commenting"), " Unfollow"]
        end
    end
  end


  def render("follow_button.html", %{user_id: user_id, category_id: category_id}) do
    follow_or_unfollow(user_id, category_id)
  end
end