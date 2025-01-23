defmodule Tpn.Cache do
  use Nebulex.Cache,
    otp_app: :tpn,
    adapter: Nebulex.Adapters.Local
end
