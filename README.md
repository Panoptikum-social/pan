# Panoptikum

Panoptikum (or short Pan) is a webapplication written in [Phoenix](http://www.phoenixframework.org/)
that represents a podcast discovery and community website.

It is licensed under the AGPL license.
The project website with more information on the project can be found at https://www.panoptikum.io
If you are interested and want to get in touch, write an email to [Stefan](mailto:stefan@panoptikum.io).

## Setup

### Prerequirements
* Make sure you have [Elixir](https://elixir-lang.org) installed.
* Make sure you have [Node.js](https://nodejs.org) installed.
* Make sure you have [PostgreSQL](https://www.postgresql.org) installed and running.
* Make sure you have [Elasticsearch](https://www.elastic.co/products/elasticsearch) installed and running.

### Install dependencies
* Install Elixir's dependencies with `mix deps.get`
* Install Node.js dependencies with `npm install` _inside the assets folder_

### Configuration
* Copy `config/dev.secret.exs.example` to `config/dev.secret.exs` and insert your own data
* Copy `config/prod.secret.exs.example` to `config/prod.secret.exs` and insert your own data

### Database and demo data
* Setup your database with `mix ecto.setup`
* Import demo data
  * Uncompress `materials/pan_dev.sql.gz`
  * Import data with `psql pan_dev < pan_dev.sql` _inside the materials folder_

### Run locally
* Start Phoenix endpoint with `mix phx.server`
* Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
* Login as Admin using username `admin` and password `changeme`

### Bonus
* To view sent emails while developing you can visit [`localhost:4000/sent_emails`](http://localhost:4000/sent_emails)
* To rebuilt the search index login as `admin` and visit [`localhost:4000/admin/search/push_all`](http://localhost:4000/admin/search/push_all)
