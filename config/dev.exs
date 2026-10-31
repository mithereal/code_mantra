import Config

# Configure your database for local development
config :code_mantra, CodeMantra.Repo,
       username: "postgres",
       password: "postgres",
       hostname: "localhost",
       database: "code_mantra_dev",
       stacktrace: true,
       show_sensitive_data_on_connection_error: true,
       pool_size: 10

# For development, we disable cache and enable reloading
config :code_mantra, CodeMantraWeb.Endpoint,
       http: [ip: {127, 0, 0, 1}, port: 4000],
       debug_errors: true,
       code_reloader: true,
       check_origin: false,
       watchers: [
         esbuild: {Esbuild, :install_and_run, [:code_mantra, ~w(--sourcemap=inline --watch)]},
         tailwind: {Tailwind, :install_and_run, [:code_mantra, ~w(--watch)]}
       ]

# Watch static and template files for browser reloading in dev
config :code_mantra, CodeMantraWeb.Endpoint,
       live_reload: [
         patterns: [
           ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
           ~r"lib/code_mantra_web/(controllers|live|components)/.*(ex|heex)$"
         ]
       ]

# Enable dev routes for dashboard and mailbox
config :code_mantra, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime