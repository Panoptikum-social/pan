defmodule PanWeb.Live.Podcast.RecommendationsList do
  use Surface.Component
  alias PanWeb.Live.Podcast.RecommendForm
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  prop(changeset, :map, required: true)
  prop(recommendations, :list, required: true)

  def render(assigns) do
    ~F"""
    <h2 id="recommendations" class="text-2xl">Recommendations</h2>

    {#if @recommendations != []}
      <span class="pull-right"><a href="https://panoptikum.io/complaints">Complain</a></span>

      <table class="table table-condensed table-bordered table-striped">
        <thead>
          <tr>
            <th>User</th>
            <th>Recommendation</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          {#for recommendation <- @recommendations}
            <tr>
              <td>
                {#if @current_user_id == recommendation.user_id}
                  <nobr>
                    {social_text = "👍 " <> @podcast.title <> "%0A💬 " <> truncate_string(recommendation.comment, 220) <> "%0A🔊 "}
                    {facebook_text = @podcast.title <> "%0A" <> truncate_string(recommendation.comment, 220)}
                    {social_url = URI.encode_www_form(podcast_frontend_url(Endpoint, :show, @podcast))}

                    <a href={"https://twitter.com/intent/tweet?text=#{social_text}&url=#{social_url}"}
                       class="social-button twitter-button">Tweet it</a>
                    <a href={"https://www.facebook.com/sharer/sharer.php?u=#{social_url}&quote=#{facebook_text}"},
                       class="social-button facebook-button">Share on Facebook</a>
                    <a href={"mailto:?subject=#{social_text}&body=#{social_url}"}
                       class="social-button email-button">Send an E-Mail</a>
                  </nobr><br/>
                {/if}
                {recommendation.user.name}
              </td>
              <td>{recommendation.comment}</td>
              <td align="right">
                {recommendation.inserted_at |> Timex.to_date |> Timex.format!("%e.%m.%Y", :strftime)}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    {/if}

    <RecommendForm current_user_id={@current_user_id}
                   changeset={@changeset}
                   podcast={@podcast} />
    """
  end
end
