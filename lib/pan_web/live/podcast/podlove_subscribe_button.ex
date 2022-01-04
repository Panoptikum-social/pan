defmodule PanWeb.Live.Podcast.PodloveSubscribeButton do
  use Surface.LiveComponent

  prop(for, :map, required: true)

  def render(assigns) do
    ~F"""
    <div id="subscribe-button">
      <script class="podlove-subscribe-button"
              src="/subscribe-button/javascripts/app.js"
              data-language="en"
              data-size="medium"
              data-json-data="podcastData"
              data-colors="ED5565"
              data-buttonid="123abc"
              data-format="rectangle">
      </script>

      <script>
        window.podcastData = {
          "title": "<%= ej(@podcast.title || "") %>",
          "subtitle": "<%= ej(@podcast.summary || "") %>",
          "description": "<%= ej(@podcast.description || "") %>",
          "cover": "<%= @podcast.image_url %>",
          "feeds": [
          <%= for feed <- @podcast.feeds do %>
            {
              "type": "audio",
              "format": "mp3",
              "url": "<%= feed.self_link_url %>",
              "variant": "high"
            },
          <% end %>
          ]
        }
      </script>
    </div>
    """
  end
end
