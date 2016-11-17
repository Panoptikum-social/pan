defmodule Pan.MailboxChannel do
  use Pan.Web, :channel

  def join("mailboxes:" <> user_id, _params, socket) do
    if String.to_integer(user_id) == socket.assigns[:current_user_id] do
      {:ok, socket}
    else
      {:error, "That's not your channel"}
    end
  end
end