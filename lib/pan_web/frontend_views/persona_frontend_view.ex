defmodule PanWeb.PersonaFrontendView do
  use PanWeb, :view
  alias Pan.Repo
  alias PanWeb.Follow
  alias PanWeb.Like
  alias PanWeb.Persona
  alias PanWeb.Endpoint

  def markdown(content) do
    if content do
      content
      |> Earmark.as_html!()
      |> HtmlSanitizeEx.html5()
      |> raw()
    end
  end

  def pro(user) do
    PanWeb.UserFrontendView.pro(user)
  end

  def like_or_unlike(enjoyer_id, persona_id) do
    case Repo.get_by(Like,
           enjoyer_id: enjoyer_id,
           persona_id: persona_id
         ) do
      nil ->
        content_tag :button,
          class: "btn btn-warning",
          data: [type: "persona", event: "like", action: "like", id: persona_id] do
          [Persona.likes(persona_id), " ", icon("heart-heroicons-outline"), " Like"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "persona", event: "like", action: "unlike", id: persona_id] do
          [Persona.likes(persona_id), " ", icon("heart-heroicons-outline"), " Unlike"]
        end
    end
  end

  def render("like_button.html", %{current_user_id: current_user_id, persona_id: persona_id}) do
    like_or_unlike(current_user_id, persona_id)
  end

  def render("follow_button.html", %{current_user_id: current_user_id, persona_id: persona_id}) do
    follow_or_unfollow(current_user_id, persona_id)
  end

  def render("datatable.json", %{
        personas: personas,
        draw: draw,
        records_total: records_total,
        records_filtered: records_filtered
      }) do
    %{
      draw: draw,
      recordsTotal: records_total,
      recordsFiltered: records_filtered,
      data: Enum.map(personas, &persona_json/1)
    }
  end

  def follow_or_unfollow(follower_id, persona_id) do
    case Repo.get_by(Follow,
           follower_id: follower_id,
           persona_id: persona_id
         ) do
      nil ->
        content_tag :button,
          class: "btn btn-primary",
          data: [type: "persona", event: "follow", action: "follow", id: persona_id] do
          [Persona.follows(persona_id), " ", icon("annotation-heroicons-outline"), " Follow"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "persona", event: "follow", action: "unfollow", id: persona_id] do
          [Persona.follows(persona_id), " ", icon("commenting"), " Unfollow"]
        end
    end
  end

  def format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end

  def persona_json(persona) do
    %{id: persona.id, pid: persona.pid, name: persona_button(persona, &persona_frontend_path/3)}
  end

  def persona_button(persona, path) do
    [
      link([icon("user-heroicons-outline"), " ", persona.name],
        to: path.(Endpoint, :show, persona),
        class: "btn btn-xs btn-lavender"
      )
    ]
    |> Enum.map_join(&my_safe_to_string/1)
  end

  def slug_with_gigs(conn, action, []) do
    slug_with_gigs(conn, action, page: 1)
  end

  def slug_with_gigs(conn, _, page: page) do
    conn.assigns[:persona].pid <> "?page=#{page}#gigs"
  end
end
