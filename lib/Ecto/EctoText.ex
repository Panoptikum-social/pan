defmodule Ecto.EctoText do
  use Ecto.Type
  def type(), do: :string
  def cast(string), do: {:ok, string}
  def load(string), do: {:ok, string}
  def dump(string), do: {:ok, string}
  def embed_as(_), do: :dump
end
