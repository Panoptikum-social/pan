defmodule PanWeb.Component.CurationGrade do
  use PanWeb, :html
  alias PanWeb.Curation

  attr :grade, :atom, required: true
  attr :count, :integer, default: nil

  def badge(assigns) do
    ~H"""
    <span class={["badge badge-sm badge-outline whitespace-nowrap", badge_class(@grade)]}>
      <span :if={@count}>{@count}×</span> {Curation.grade_label(@grade)}
    </span>
    """
  end

  defp badge_class(:recommended), do: "badge-success"
  defp badge_class(:rather_recommended), do: "badge-success"
  defp badge_class(:indifferent), do: "badge-neutral"
  defp badge_class(:rather_declined), do: "badge-error"
  defp badge_class(:declined), do: "badge-error"
end
