defmodule PanWeb.CategoryFrontendView do
  use Pan.Web, :view
  alias PanWeb.Category
  alias Pan.Repo
  alias PanWeb.Like
  alias PanWeb.Follow
  import Scrivener.HTML


  def list_group_item_cycle(counter) do
    Enum.at(["list-group-item-info", "list-group-item-danger",
             "list-group-item-warning", "list-group-item-primary", "list-group-item-success"], rem(counter, 5))
  end


  def like_or_unlike(user_id, category_id) do
    case Repo.get_by(Like, enjoyer_id: user_id,
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


  def follow_or_unfollow(user_id, category_id) do
    case Repo.get_by(Follow, follower_id: user_id,
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


  def render("like_button.html", %{user_id: user_id, category_id: category_id}) do
    like_or_unlike(user_id, category_id)
  end


  def render("follow_button.html", %{user_id: user_id, category_id: category_id}) do
    follow_or_unfollow(user_id, category_id)
  end
end