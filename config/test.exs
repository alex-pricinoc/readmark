import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :readmark, Readmark.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: "readmark_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :readmark, ReadmarkWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "SV52PuPp5p1nokCnq2jufYZQOICbtBusoGLRsNvzyeW7mJAyTaG8NNdori/0wxRc",
  server: false

# In test we don't send emails.
config :readmark, Readmark.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :readmark, Oban, testing: :inline, plugins: false, queues: false

config :readmark, :readability, ReadabilityMock
