defmodule Tpn.Repo do
  use Ecto.Repo,
    otp_app: :tpn,
    adapter: Ecto.Adapters.Postgres
end
