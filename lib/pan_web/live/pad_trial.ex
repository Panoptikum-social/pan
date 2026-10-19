defmodule PanWeb.Live.PadTrial do
  use PanWeb, :live_view

  # Trial for community pads (dev and qa only): one hardcoded pad, edited in
  # CodeMirror and synced over PanWeb.PadTrialChannel. No preview yet.
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Pad trial")}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-2xl mb-4">Pad trial</h1>
      <p class="mb-4">
        Open this page in a second browser and type in both. The text lives in
        memory only and is gone a few seconds after the last browser leaves.
      </p>
      <div
        id="pad-trial"
        phx-hook="PadTrial"
        phx-update="ignore"
        data-topic="pad_trial:trial"
        class="border border-base-300 rounded min-h-64"
      >
      </div>
    </div>
    """
  end
end
