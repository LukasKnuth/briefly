import Config

config :briefly,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :briefly, BrieflyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BrieflyWeb.ErrorHTML, json: BrieflyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Briefly.PubSub

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.0",
  briefly: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configures Elixir's Logger
config :logger, :default_handler, level: :error

config :logger, :default_formatter,
  format: "$time [$level] $message $metadata\n",
  metadata: [:request_id, :error]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
