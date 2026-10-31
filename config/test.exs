import Config

# Configure your database for testing
config :code_mantra, CodeMantra.Repo,
       username: "postgres",
       password: "postgres",
       hostname: "localhost",
       database: "code_mantra_test#{System.get_env("MIX_TEST_PARTITION")}",
       pool: Ecto.Adapters.SQL.Sandbox,
       pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :code_mantra, CodeMantraWeb.Endpoint,
       http: [ip: {127, 0, 0, 1}, port: 4002],
       secret_key_base: "test_secret_key_base_placeholder_for_secure_isolation_testing",
       server: false

# Print only warnings and errors during test runs
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime