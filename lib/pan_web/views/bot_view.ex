defmodule PanWeb.BotView do
  use PanWeb, :view

  def render("webhook.json", %{challenge: challenge}) do
    challenge
  end
end
