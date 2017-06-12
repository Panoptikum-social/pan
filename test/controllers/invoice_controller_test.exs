defmodule Pan.InvoiceControllerTest do
  use Pan.ConnCase

  alias Pan.Invoice
  @valid_attrs %{content_type: "some content", filename: "some content", path: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, invoice_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing invoices"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, invoice_path(conn, :new)
    assert html_response(conn, 200) =~ "New invoice"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, invoice_path(conn, :create), invoice: @valid_attrs
    assert redirected_to(conn) == invoice_path(conn, :index)
    assert Repo.get_by(Invoice, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, invoice_path(conn, :create), invoice: @invalid_attrs
    assert html_response(conn, 200) =~ "New invoice"
  end

  test "shows chosen resource", %{conn: conn} do
    invoice = Repo.insert! %Invoice{}
    conn = get conn, invoice_path(conn, :show, invoice)
    assert html_response(conn, 200) =~ "Show invoice"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, invoice_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    invoice = Repo.insert! %Invoice{}
    conn = get conn, invoice_path(conn, :edit, invoice)
    assert html_response(conn, 200) =~ "Edit invoice"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    invoice = Repo.insert! %Invoice{}
    conn = put conn, invoice_path(conn, :update, invoice), invoice: @valid_attrs
    assert redirected_to(conn) == invoice_path(conn, :show, invoice)
    assert Repo.get_by(Invoice, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    invoice = Repo.insert! %Invoice{}
    conn = put conn, invoice_path(conn, :update, invoice), invoice: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit invoice"
  end

  test "deletes chosen resource", %{conn: conn} do
    invoice = Repo.insert! %Invoice{}
    conn = delete conn, invoice_path(conn, :delete, invoice)
    assert redirected_to(conn) == invoice_path(conn, :index)
    refute Repo.get(Invoice, invoice.id)
  end
end
