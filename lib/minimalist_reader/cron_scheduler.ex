defmodule MinimalistReader.CronScheduler do
  @moduledoc """
  Uses the `quantum` dependency to run tasks on a CRON-like schedule.
  The actual configuration is found in `config/runtime.ex`
  """
  use Quantum, otp_app: :minimalist_reader
end
