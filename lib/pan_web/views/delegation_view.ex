defmodule PanWeb.DelegationView do
  use Pan.Web, :view

  def render("datatable.json", %{delegations: delegations}) do
    %{delegations: Enum.map(delegations, &delegation_json/1)}
  end

  def delegation_json(delegation) do
    %{
      id: delegation.id,
      persona_id: delegation.persona_id,
      persona_name: delegation.persona.name,
      delegate_id: delegation.delegate_id,
      delegate_name: delegation.delegate.name,
      actions: datatable_actions(delegation, &delegation_path/3)
    }
  end
end
