import Config
require Logger

if System.get_env("PHX_SERVER") do
  config :minimalist_reader, MinimalistReaderWeb.Endpoint, server: true
end

config :minimalist_reader, MinimalistReader.Config,
  file_path: System.get_env("CONFIG_PATH") || "/etc/minimalist_reader/feeds.yml"

config :minimalist_reader, MinimalistReaderWeb.PageController,
  home_action: System.get_env("HOME_ACTION") || "today"

refresh_job =
  with schedule when is_binary(schedule) <- System.get_env("CRON_REFRESH", nil) do
    [schedule: Crontab.CronExpression.Parser.parse!(schedule)]
  else
    _ ->
      Logger.info("Env variable 'CRON_REFRESH' not set, automatic refresh DISABLED")
      [state: :inactive]
  end

config :minimalist_reader, MinimalistReader.CronScheduler,
  overlap: false,
  jobs: [
    startup: [task: {MinimalistReader, :refresh, []}, schedule: "@reboot"],
    refresh: [task: {MinimalistReader, :refresh, []}] |> Keyword.merge(refresh_job)
  ]

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  # TODO do we need a config option for the "url.scheme"?
  config :minimalist_reader, MinimalistReaderWeb.Endpoint,
    url: [host: host, scheme: "http"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
