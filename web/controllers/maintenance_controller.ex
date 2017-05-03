defmodule Pan.MaintenanceController do
  use Pan.Web, :controller

  def vienna_beamers(conn, _params) do
    redirect(conn, external: "https://blog.panoptikum.io/vienna-beamers/")
  end

  def blog_2016(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2016/#{month}/#{day}/#{file}")
  end

  def blog_2017(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2017/#{month}/#{day}/#{file}")
  end


  def fix(conn, _params) do

    render(conn, "done.html", %{})
  end
end
