import Config
require Logger

if config_env() == :prod do
  config :briefly, Briefly.Config,
    file_path: System.get_env("CONFIG_PATH") || "/etc/briefly/feeds.yml"

  config :briefly, BrieflyWeb.PageController,
    home_action: System.get_env("HOME_ACTION") || "yesterday"

  timezone = System.get_env("TZ") || "Etc/UTC"
  # NOTE: this is validated in `Briefly.Application` before launch!
  config :briefly, Briefly, timezone: timezone

  refresh_job =
    with schedule when is_binary(schedule) <- System.get_env("CRON_REFRESH", nil) do
      [schedule: Crontab.CronExpression.Parser.parse!(schedule)]
    else
      _ ->
        Logger.info("Env variable 'CRON_REFRESH' not set, automatic refresh DISABLED")
        [state: :inactive]
    end

  config :briefly, Briefly.CronScheduler,
    overlap: false,
    timezone: timezone,
    jobs: [
      startup: [task: {Briefly, :refresh, []}, schedule: "@reboot"],
      refresh: [task: {Briefly, :refresh, []}] |> Keyword.merge(refresh_job)
    ]

  port = String.to_integer(System.get_env("PORT") || "4000")

  config :briefly, BrieflyWeb.Endpoint,
    server: true,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ]
end
