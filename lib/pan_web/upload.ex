defmodule PanWeb.Upload do
  @moduledoc """
  Helpers for files uploaded through forms and the API.
  """

  @doc """
  The client sends the filename of an upload (`Plug.Upload.filename`) as it
  likes, "../../etc/x" included. Keeps only the last path segment, so the
  file stays in the upload directory.
  """
  def safe_filename(filename) do
    case Path.basename(filename) do
      name when name in ["", ".", ".."] -> "upload"
      name -> name
    end
  end
end
