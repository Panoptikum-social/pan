The app stores uploaded files (OPML, images, invoices) under `/var/phoenix/pan-uploads/`. This path is hardcoded in:
- `lib/pan_web/frontend_controller/opml_frontend_controller.ex`
- `lib/pan_web/controllers/opml_controller.ex`
- `lib/pan_web/api/controllers/opml_controller.ex`
- `lib/pan_web/controllers/image_controller.ex`
- `lib/pan_web/controllers/invoice_controller.ex`
- `lib/pan_web/models/image.ex`

The directory does **not** exist on fresh dev machines. `File.mkdir_p` and `File.cp` both silently ignore errors (return values are discarded), so uploads appear to succeed but the file is never written. The import then crashes with `{:error, :enoent}` at `File.read(path)`.

To set up a new dev machine:
```bash
sudo mkdir -p /var/phoenix/pan-uploads/opml /var/phoenix/pan-uploads/images /var/phoenix/pan-uploads/invoices
sudo chown -R $(whoami):$(whoami) /var/phoenix
```

**Why:** Production server has this directory pre-configured; dev machines don't get it automatically.
**How to apply:** When seeing `{:error, :enoent}` in the OPML/image/invoice import flow, check if `/var/phoenix/pan-uploads/` exists before looking for code bugs.
