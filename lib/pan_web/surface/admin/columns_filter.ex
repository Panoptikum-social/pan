defmodule PanWeb.Surface.Admin.ColumnsFilter do
  alias PanWeb.Surface.Admin.Naming

  def number_columns(assigns) do
    assigns.columns
    |> Enum.filter(fn c -> c.type in [:id, :integer, :float] end)
  end

  def boolean_columns(assigns) do
    assigns.columns
    |> Enum.filter(fn c -> c.type == :boolean end)
  end

  def datetime_columns(assigns) do
    assigns.columns
    |> Enum.filter(fn c -> c.type in [:datetime, :naive_datetime] end)
  end

  def string_columns(assigns) do
    assigns.columns
    |> Enum.filter(fn c -> c.type in [:string, :"Ecto.UUID"] end)
  end

  def text_columns(assigns) do
    assigns.columns
    |> Enum.filter(fn c -> c.type in [Ecto.EctoText] end)
  end
end
