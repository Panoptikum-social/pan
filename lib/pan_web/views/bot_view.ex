defmodule PanWeb.BotView do
  use Pan.Web, :view

  def render("webhook.json", %{ challenge: challenge}) do
    challenge
  end
end
