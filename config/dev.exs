import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :briefly, BrieflyWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "6U1NzVev0Lo53OVMlMFKyukUD9IXjHdH5tUmsMft6E7sZKn3+yE9OqxDy1WJ+bMi",
  watchers: [
    tailwind: {Tailwind, :install_and_run, [:briefly, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :briefly, BrieflyWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/briefly_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# ----- APPLICATION SPECIFIC CONFIG --------
config :briefly, Briefly, timezone: "Europe/Berlin"
config :briefly, Briefly.Config, file_path: "test_feeds.yml"
config :briefly, BrieflyWeb.PageController, home_action: "yesterday"

config :briefly, Briefly.CronScheduler,
  overlap: false,
  jobs: [
    startup: [task: {Briefly, :refresh, []}, schedule: "@reboot"],
    refresh: [task: {Briefly, :refresh, []}, schedule: "*/20 * * * *"]
  ]
