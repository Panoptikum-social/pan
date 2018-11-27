defmodule PanWeb.InvoiceController do
  use Pan.Web, :controller
  alias PanWeb.Invoice

  def index(conn, _params) do
    invoices = Repo.all(Invoice)
               |> Repo.preload(:user)
    render(conn, "index.html", invoices: invoices)
  end


  def new(conn, _params) do
    changeset = Invoice.changeset(%Invoice{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"invoice" => invoice_params}) do
    user_id =
      if invoice_params["user_id"] != "", do: String.to_integer(invoice_params["user_id"]), else: nil

    destination_path =
      if upload = invoice_params["file"] do
        File.mkdir_p("/var/phoenix/pan-uploads/invoices/#{invoice_params["user_id"]}")
        path = "/var/phoenix/pan-uploads/invoices/#{invoice_params["user_id"]}/#{upload.filename}"
        File.cp(upload.path, path)
        path
      else
        ""
      end

    changeset =
      if upload do
        Invoice.changeset(%Invoice{content_type: upload.content_type,
                                   filename: upload.filename,
                                   path: destination_path,
                                   user_id: user_id})
      else
        Invoice.changeset(%Invoice{content_type: nil,
                                   filename: nil,
                                   path: destination_path,
                                   user_id: user_id})
      end

    case Repo.insert(changeset) do
      {:ok, _invoice} ->
        conn
        |> put_flash(:info, "Invoice uploaded successfully.")
        |> redirect(to: invoice_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    invoice = Repo.get!(Invoice, id)
    render(conn, "show.html", invoice: invoice)
  end


  def edit(conn, %{"id" => id}) do
    invoice = Repo.get!(Invoice, id)
    changeset = Invoice.changeset(invoice)
    render(conn, "edit.html", invoice: invoice, changeset: changeset)
  end


  def update(conn, %{"id" => id, "invoice" => invoice_params}) do
    invoice = Repo.get!(Invoice, id)
    changeset = Invoice.changeset(invoice, invoice_params)

    case Repo.update(changeset) do
      {:ok, invoice} ->
        conn
        |> put_flash(:info, "Invoice updated successfully.")
        |> redirect(to: invoice_path(conn, :show, invoice))
      {:error, changeset} ->
        render(conn, "edit.html", invoice: invoice, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    invoice = Repo.get!(Invoice, id)

    File.rm(invoice.path)
    Repo.delete!(invoice)

    conn
    |> put_flash(:info, "Invoice deleted successfully.")
    |> redirect(to: invoice_path(conn, :index))
  end
end
