import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :briefly, BrieflyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "DKP0OukXwQz1VAlrW06p4ak9tnIrM7Oy3MtTMlH+y+GuaTlkYPEi45cQy5tUDIi9",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# ------ APPLICATION CONFIG -------
config :briefly, Briefly, timezone: "Etc/UTC"
config :briefly, Briefly.Config, file_path: "test/fixtures/integration/config_success.yml"
config :briefly, BrieflyWeb.PageController, home_action: "yesterday"

# Allow global stubbing of requests sent out by Req
config :briefly, Briefly.HttpClient, opts: [plug: {Req.Test, Briefly.HttpClientMock}]
