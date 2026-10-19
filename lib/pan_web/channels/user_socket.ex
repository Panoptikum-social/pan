defmodule PanWeb.UserSocket do
  use Phoenix.Socket

  channel "pad:*", PanWeb.PadChannel

  # The pad page signs the logged-in user's id into the page; a socket
  # without a valid token is refused. Reconnects reuse the token, so it is
  # valid for a week after the page was loaded.
  @max_age 7 * 24 * 60 * 60

  def sign_token(user_id), do: Phoenix.Token.sign(PanWeb.Endpoint, "user socket", user_id)

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(PanWeb.Endpoint, "user socket", token, max_age: @max_age) do
      {:ok, user_id} -> {:ok, assign(socket, :user_id, user_id)}
      {:error, _reason} -> :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(_socket), do: nil
end
