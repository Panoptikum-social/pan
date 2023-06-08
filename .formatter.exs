[
  plugins: [Phoenix.LiveView.HTMLFormatter],
  import_deps: [:ecto, :ecto_sql, :phoenix],
  inputs: ["*.{heex,ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{heex,ex,exs}"],
  subdirectories: ["priv/*/migrations"],
  surface_inputs: ["{lib,test}/**/*.{ex,exs,sface}"],
  locals_without_parens: [form_for: 3, form_for: 4]
]
