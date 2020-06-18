defmodule Pan.InvoiceControllerTest do
  use PanWeb.ConnCase

  alias PanWeb.Invoice
  @valid_attrs %{content_type: "some content", filename: "some content", path: "some content"}
  @invalid_attrs %{}

  # FIXME
  @tag :currently_broken
  test "lists all entries on index", %{conn: conn} do
    conn = get(conn, invoice_path(conn, :index))
    assert html_response(conn, 200) =~ "Listing invoices"
  end

  # FIXME
  @tag :currently_broken
  test "renders form for new resources", %{conn: conn} do
    conn = get(conn, invoice_path(conn, :new))
    assert html_response(conn, 200) =~ "New invoice"
  end

  # FIXME
  @tag :currently_broken
  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post(conn, invoice_path(conn, :create), invoice: @valid_attrs)
    assert redirected_to(conn) == invoice_path(conn, :index)
    assert Repo.get_by(Invoice, @valid_attrs)
  end

  # FIXME
  @tag :currently_broken
  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post(conn, invoice_path(conn, :create), invoice: @invalid_attrs)
    assert html_response(conn, 200) =~ "New invoice"
  end

  # FIXME
  @tag :currently_broken
  test "shows chosen resource", %{conn: conn} do
    invoice = Repo.insert!(%Invoice{})
    conn = get(conn, invoice_path(conn, :show, invoice))
    assert html_response(conn, 200) =~ "Show invoice"
  end

  # FIXME
  @tag :currently_broken
  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent(404, fn ->
      get(conn, invoice_path(conn, :show, -1))
    end)
  end

  # FIXME
  @tag :currently_broken
  test "renders form for editing chosen resource", %{conn: conn} do
    invoice = Repo.insert!(%Invoice{})
    conn = get(conn, invoice_path(conn, :edit, invoice))
    assert html_response(conn, 200) =~ "Edit invoice"
  end

  # FIXME
  @tag :currently_broken
  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    invoice = Repo.insert!(%Invoice{})
    conn = put(conn, invoice_path(conn, :update, invoice), invoice: @valid_attrs)
    assert redirected_to(conn) == invoice_path(conn, :show, invoice)
    assert Repo.get_by(Invoice, @valid_attrs)
  end

  # FIXME
  @tag :currently_broken
  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    invoice = Repo.insert!(%Invoice{})
    conn = put(conn, invoice_path(conn, :update, invoice), invoice: @invalid_attrs)
    assert html_response(conn, 200) =~ "Edit invoice"
  end

  # FIXME
  @tag :currently_broken
  test "deletes chosen resource", %{conn: conn} do
    invoice = Repo.insert!(%Invoice{})
    conn = delete(conn, invoice_path(conn, :delete, invoice))
    assert redirected_to(conn) == invoice_path(conn, :index)
    refute Repo.get(Invoice, invoice.id)
  end
end
