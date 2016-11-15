defmodule Pan.UserChannel do
  use Pan.Web, :channel

  def join("users:" <> user_id, _params, socket) do
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end
end