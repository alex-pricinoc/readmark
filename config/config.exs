# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :readmark, ecto_repos: [Readmark.Repo]

config :readmark, Readmark.Repo, migration_timestamps: [type: :utc_datetime_usec]

# Configures the endpoint
config :readmark, ReadmarkWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: ReadmarkWeb.ErrorHTML, json: ReadmarkWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Readmark.PubSub,
  live_view: [signing_salt: "QkfgAvzd"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :readmark, Readmark.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Content Security Policy (CSP)
# override this in prod.exs
config :readmark,
       :content_security_policy,
       "default-src 'self' 'unsafe-eval' 'unsafe-inline'; connect-src 'self' wss:; img-src 'self' https: data:; font-src 'self' data:;"

# Oban
config :readmark, Oban,
  repo: Readmark.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: :timer.hours(24)},
    {Oban.Plugins.Cron, crontab: [{"@weekly", Readmark.Workers.Pruner}]}
  ],
  queues: [default: 5, kindle: 1, pruning: 1]

config :readmark, :readability, Readability

config :elixir, :time_zone_database, Tz.TimeZoneDatabase
config :tz, reject_periods_before_year: NaiveDateTime.utc_now().year - 1
config :tz, build_dst_periods_until_year: NaiveDateTime.utc_now().year + 2

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
