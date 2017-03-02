defmodule Pan.PersonaFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML
  alias Pan.Repo
  alias Pan.Follow
  alias Pan.Like
  alias Pan.Persona


  def markdown(content) do
    if content do
      content
      |> Earmark.as_html!()
      |> HtmlSanitizeEx.html5()
      |> raw()
    end
  end


  def pro(user) do
    Pan.UserFrontendView.pro(user)
  end


  def like_or_unlike(enjoyer_id, persona_id) do
    case Repo.get_by(Like, enjoyer_id: enjoyer_id,
                           persona_id: persona_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "persona",
                                    event: "like",
                                    action: "like",
                                    id: persona_id] do
          [Persona.likes(persona_id), " ", fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "persona",
                                    event: "like",
                                    action: "unlike" ,
                                    id: persona_id] do
          [Persona.likes(persona_id), " ", fa_icon("heart"), " Unlike"]
        end
    end
  end


  def render("like_button.html", %{current_user_id: current_user_id, persona_id: persona_id}) do
    like_or_unlike(current_user_id, persona_id)
  end

  def render("follow_button.html", %{current_user_id: current_user_id, persona_id: persona_id}) do
    follow_or_unfollow(current_user_id, persona_id)
  end


  def follow_or_unfollow(follower_id, persona_id) do
    case Repo.get_by(Follow, follower_id: follower_id,
                             persona_id: persona_id) do
      nil ->
        content_tag :button, class: "btn btn-primary",
                             data: [type: "persona",
                                    event: "follow",
                                    action: "follow",
                                    id: persona_id] do
          [Persona.follows(persona_id), " ", fa_icon("commenting-o"), " Follow"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "persona",
                                    event: "follow",
                                    action: "unfollow" ,
                                    id: persona_id] do
          [Persona.follows(persona_id), " ", fa_icon("commenting"), " Unfollow"]
        end
    end
  end


  def format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end
end