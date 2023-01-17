defmodule Readmark.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ReadmarkWeb.Telemetry,
      # Start the Ecto repository
      Readmark.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Readmark.PubSub},
      # Start Finch
      {Finch, name: Readmark.Finch},
      # Start the Endpoint (http/https)
      ReadmarkWeb.Endpoint,
      # Start a worker by calling: Readmark.Worker.start_link(arg)
      # {Readmark.Worker, arg}
      {Task.Supervisor, name: Readmark.TaskSupervisor},
      %{id: Readmark.ArticleFetcher, start: {Readmark.ArticleFetcher, :start_link, []}}
      # Start Oban
      {Oban, Application.fetch_env!(:readmark, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Readmark.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ReadmarkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
