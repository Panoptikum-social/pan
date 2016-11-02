defmodule Pan.CategoryFrontendView do
  use Pan.Web, :view
  use Pan.Web, :controller

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
end
