defmodule Tpn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TpnWeb.Telemetry,
      Tpn.Repo,
      {DNSCluster, query: Application.get_env(:tpn, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tpn.PubSub},
      # Start the Finch HTTP client for sending emails
      # {Finch, name: Tpn.Finch},
      # Start a worker by calling: Tpn.Worker.start_link(arg)
      # {Tpn.Worker, arg},
      # Start to serve requests, typically the last entry
      TpnWeb.Endpoint,
      {Tpn.Cache, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tpn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TpnWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
