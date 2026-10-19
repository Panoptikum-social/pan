defmodule PanWeb.UserSocket do
  use Phoenix.Socket

  # Trial for community pads (dev and qa only, no authentication yet)
  channel "pad_trial:*", PanWeb.PadTrialChannel

  @impl true
  def connect(_params, socket, _connect_info), do: {:ok, socket}

  @impl true
  def id(_socket), do: nil
end
