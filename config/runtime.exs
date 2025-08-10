import Config
require Logger

if config_env() == :prod do
  config :briefly, Briefly.Config,
    file_path: System.get_env("CONFIG_PATH") || "/etc/briefly/feeds.yml"

  config :briefly, BrieflyWeb.PageController,
    home_action: System.get_env("HOME_ACTION") || "yesterday"

  timezone = System.get_env("TZ") || "Etc/UTC"

  unless Timex.is_valid_timezone?(timezone) do
    raise """
    The timezone specified in the TZ environment variable is invalid.
    """
  end

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
    jobs: [
      startup: [task: {Briefly, :refresh, []}, schedule: "@reboot"],
      refresh: [task: {Briefly, :refresh, []}] |> Keyword.merge(refresh_job)
    ]

  port = String.to_integer(System.get_env("PORT") || "4000")

  # TODO do we need a config option for the "url.scheme"?
  config :briefly, BrieflyWeb.Endpoint,
    server: true,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ]
end
