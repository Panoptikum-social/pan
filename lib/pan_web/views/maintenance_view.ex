defmodule PanWeb.MaintenanceView do
  use PanWeb, :view

  # A group of related numbers: a headline value, followed by its breakdown rows.
  def stat_card(assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:unit, fn -> nil end)
      |> assign_new(:inner_block, fn -> [] end)

    ~H"""
    <div class={["card bg-base-100 border border-base-300 border-t-4 shadow-sm", @accent]}>
      <div class="card-body p-4 gap-2">
        <div class="flex items-baseline justify-between gap-4">
          <h2 class="card-title text-base">
            {icon(@icon, class: "size-5 inline opacity-60")}
            {@title}
          </h2>
          <span :if={@value} class="text-2xl font-semibold tabular-nums">
            {@value}<span :if={@unit} class="ml-1 text-sm font-normal opacity-60">{@unit}</span>
          </span>
        </div>
        <dl class="divide-y divide-base-200 text-sm">
          {render_slot(@inner_block)}
        </dl>
      </div>
    </div>
    """
  end

  def metric(assigns) do
    ~H"""
    <div class="flex justify-between gap-4 py-1">
      <dt class="opacity-70">{@label}</dt>
      <dd class="tabular-nums">{@value}</dd>
    </div>
    """
  end

  # {yellow from, red from}, based on the prod backup of 2026-10-10: ~70 stale
  # podcasts (≈ 20 min of updates at ~230 p/h), 135 retirement candidates
  # (metadata refresh failures push the count past 10 without retiring),
  # unindexed episodes ≈ 0 with the search push running every 3 minutes
  # (~10 000 new episodes a day), 5 missing thumbnails.
  @thresholds %{
    stale_podcasts: {250, 1_000},
    retirement_candidates: {250, 500},
    unindexed_episodes: {1_000, 10_000},
    thumbnails_missing: {50, 500}
  }

  # A number that should stay low: green, yellow or red by @thresholds.
  def attention_stat(assigns) do
    {yellow, red} = Map.fetch!(@thresholds, assigns.metric)

    assigns =
      assign(assigns,
        level: level(assigns.value, yellow, red),
        yellow: delimit_integer(yellow, " "),
        red: delimit_integer(red, " ")
      )

    ~H"""
    <div class={["stat", level_class(@level)]}>
      <div class="stat-figure">
        <span class={["status status-xl", status_class(@level)]} aria-label={@level}></span>
      </div>
      <div class="stat-title">{@title}</div>
      <div class="stat-value text-3xl tabular-nums">{delimit_integer(@value, " ")}</div>
      <div :if={assigns[:desc]} class="stat-desc">{@desc}</div>
      <div class="stat-desc opacity-70">yellow ≥ {@yellow}, red ≥ {@red}</div>
    </div>
    """
  end

  defp level(value, _yellow, red) when value >= red, do: "error"
  defp level(value, yellow, _red) when value >= yellow, do: "warning"
  defp level(_value, _yellow, _red), do: "success"

  # spelled out, so Tailwind picks the classes up
  defp level_class("error"), do: "bg-error/10"
  defp level_class("warning"), do: "bg-warning/15"
  defp level_class("success"), do: "bg-success/10"

  defp status_class("error"), do: "status-error"
  defp status_class("warning"), do: "status-warning"
  defp status_class("success"), do: "status-success"

  def delimit_integer(number, delimiter) do
    abs(number)
    |> Integer.to_charlist()
    |> :lists.reverse()
    |> delimit_integer(delimiter, [])
  end

  defp delimit_integer([a, b, c, d | tail], delimiter, acc) do
    delimit_integer([d | tail], delimiter, [delimiter, c, b, a | acc])
  end

  defp delimit_integer(list, _, acc) do
    :lists.reverse(list) ++ acc
  end
end
