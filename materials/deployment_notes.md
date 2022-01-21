# Deployment notes

## Introspection options

* `{:ok, config} = :application.get_all_key(application)`
* `PanWeb.Podcast.__changeset__`
* `PanWeb.Podcast.__struct__`

## After deployment

* Check if websocket 2.0 works: check for error message in dev tools

## Update to Panoptikum 1.0

* Migration will take some time as new constraints are created
