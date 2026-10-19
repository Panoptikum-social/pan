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
  # podcasts (≈ 20 min of updates at ~230 p/h).
  # Retired podcasts, duplicate podcasts (the first four tabs of the
  # duplicates page) and deletable users are to be tackled by hand, so they
  # turn yellow from the first one; prod backup of 2026-10-18: 0 retired,
  # 27 duplicates, 0 deletable.
  @thresholds %{
    stale_podcasts: {250, 1_000},
    retired_podcasts: {1, 25},
    duplicate_podcasts: {1, 25},
    deletable_users: {1, 25}
  }

  # Numbers that should stay low, yellow or red by @thresholds; green ones
  # are left out, and the whole section when all are green.
  def needs_attention(assigns) do
    stats =
      for stat <- assigns.stats,
          {yellow, red} = Map.fetch!(@thresholds, stat.metric),
          level = level(stat.value, yellow, red),
          level != "success" do
        Map.merge(stat, %{
          level: level,
          yellow: delimit_integer(yellow, " "),
          red: delimit_integer(red, " ")
        })
      end

    assigns = assign(assigns, stats: stats)

    ~H"""
    <div :if={@stats != []}>
      <h2 class="text-sm font-semibold uppercase tracking-wide opacity-60 mb-2">
        Needs attention
      </h2>
      <div class="stats stats-vertical sm:stats-horizontal bg-base-100 border border-base-300 shadow-sm w-full mb-8">
        <div :for={stat <- @stats} class={["stat", level_class(stat.level)]}>
          <div class="stat-figure">
            <span class={["status status-xl", status_class(stat.level)]} aria-label={stat.level}></span>
          </div>
          <div class="stat-title">
            <.link href={stat.href} target="_blank" class="link link-hover">{stat.title}</.link>
          </div>
          <div class="stat-value text-3xl tabular-nums">{delimit_integer(stat.value, " ")}</div>
          <div class="stat-desc">{stat.desc}</div>
          <div class="stat-desc opacity-70">yellow ≥ {stat.yellow}, red ≥ {stat.red}</div>
        </div>
      </div>
    </div>
    """
  end

  defp level(value, _yellow, red) when value >= red, do: "error"
  defp level(value, yellow, _red) when value >= yellow, do: "warning"
  defp level(_value, _yellow, _red), do: "success"

  # spelled out, so Tailwind picks the classes up
  defp level_class("error"), do: "bg-error/10"
  defp level_class("warning"), do: "bg-warning/15"

  defp status_class("error"), do: "status-error"
  defp status_class("warning"), do: "status-warning"

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
