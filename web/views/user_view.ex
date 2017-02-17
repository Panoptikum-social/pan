defmodule Pan.UserView do
  use Pan.Web, :view

  def render("datatable.json", %{ users: users}) do
    %{ users: Enum.map(users, &user_json/1) }
  end


  def user_json(user) do
    %{ id:              user.id,
       name:            user.name,
       username:        user.username,
       email:           user.email,
       email_confirmed: user.email_confirmed,
       podcaster:       user.podcaster,
       admin:           user.admin,
       password_hash:   user.password_hash,
       actions:         datatable_actions(user, &user_path/3) }
  end
end