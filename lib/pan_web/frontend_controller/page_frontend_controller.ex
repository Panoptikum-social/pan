defmodule PanWeb.PageFrontendController do
  use PanWeb, :controller

  def pro_features(conn, _params) do
    render(conn, "pro_features.html")
  end
end
