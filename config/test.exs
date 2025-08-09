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
