defmodule Briefly.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Briefly.Storage,
      {Task.Supervisor, name: Briefly.TaskSupervisor},
      {Phoenix.PubSub, name: Briefly.PubSub},
      BrieflyWeb.Endpoint,
      Briefly.CronScheduler
    ]

    opts = [strategy: :one_for_one, name: Briefly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BrieflyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
