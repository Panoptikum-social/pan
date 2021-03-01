defmodule PanWeb.UserView do
  use PanWeb, :view
  alias PanWeb.Endpoint

  def render("datatable.json", %{users: users}) do
    %{users: Enum.map(users, &user_json/1)}
  end

  def user_json(user) do
    %{
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      email_confirmed: user.email_confirmed,
      podcaster: user.podcaster,
      admin: user.admin,
      pro_until: user.pro_until && PanWeb.PodcastView.format_for_vienna(user.pro_until),
      inserted_at: PanWeb.PodcastView.format_for_vienna(user.inserted_at),
      updated_at: PanWeb.PodcastView.format_for_vienna(user.updated_at),
      actions: user_actions(user, &user_path/3)
    }
  end

  def user_actions(record, path) do
    [
      "<nobr>",
      link("Unset pro",
        to: path.(Endpoint, :unset_pro, record.id),
        class: "btn btn-info btn-xs",
        data: [confirm: "Are you sure?"],
        method: :post
      ),
      " ",
      link("Show",
        to: path.(Endpoint, :show, record.id),
        class: "btn btn-default btn-xs"
      ),
      " ",
      link("Edit",
        to: path.(Endpoint, :edit, record.id),
        class: "btn btn-warning btn-xs"
      ),
      " ",
      link("Edit Password",
        to: path.(Endpoint, :edit_password, record.id),
        class: "btn btn-info btn-xs"
      ),
      " ",
      link("Delete",
        to: path.(Endpoint, :delete, record.id),
        class: "btn btn-danger btn-xs",
        method: :delete,
        data: [confirm: "Are you sure?"]
      ),
      "</nobr>"
    ]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end
end
