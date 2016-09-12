defmodule Pan.Repo do
  @moduledoc """
  In memory repository.
  """
#  use Ecto.Repo, otp_app: :pan

  def all(Pan.User) do
    [%Pan.User{id: "1", username: "informatom", name: "Stefan Haslinger", password: "test", email: "stefan.haslinger@informatom.com"}]
  end

  def all(_module), do: []

  def get(module, id) do
    Enum.find all(module), fn map -> map.id == id end
  end

  def get_by(module, params) do
    Enum.find all(module), fn map ->
      Enum.all?(params, fn {key, val} -> Map.get(map, key) == val end)
    end
  end
end
