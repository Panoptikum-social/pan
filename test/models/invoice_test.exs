defmodule Pan.InvoiceTest do
  use Pan.ModelCase

  alias PanWeb.Invoice

  @valid_attrs %{content_type: "some content", filename: "some content", path: "some content"}
  @invalid_attrs %{}

  @tag :currently_broken # FIXME
  test "changeset with valid attributes" do
    changeset = Invoice.changeset(%Invoice{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Invoice.changeset(%Invoice{}, @invalid_attrs)
    refute changeset.valid?
  end
end
