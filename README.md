# Panoptikum

Panoptikum (or short Pan) is a webapplication written in [Phoenix](http://www.phoenixframework.org/)
that represents a podcast discovery and community website.

It is licensed under the AGPL license.
The project website with more information on the project can be found at https://www.panoptikum.io
If you are interested and want to get in touch, write an email to [Stefan](mailto:stefan@panoptikum.io).

To start your Phoenix app locally:

  * setup config files
    * copy `config/dev.secret.exs.samle` to `config/dev.secret.exs` and insert your own data
    * copy `config/prod.secret.exs.samle` to `config/prod.secret.exs` and insert your own data
  * Install dependencies with `mix deps.get`
  * Setup your database with `mix ecto.setup`
  * Import demo data
    * uncompress `materials/pan_dev.sql.gz`
    * import data with `psql pan_dev < pan_dev.sql` _inside the materials folder_
  * Install Node.js dependencies with `npm install` _inside the assets folder_
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
