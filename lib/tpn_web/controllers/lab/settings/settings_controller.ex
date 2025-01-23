defmodule TpnWeb.SettingsController do
  use TpnWeb, :controller

  alias Tpn.CurrencyView
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, _params) do
    currencies = CurrencyView.get_currencies()
    unit_types = Tpn.UnitTypes.unit_types_for_select()
    records = Tpn.Settings.get_settings()
    render(conn, :index, currencies: currencies, unit_types: unit_types, records: records)
  end

  def update(conn, params) do
    # get user_id from the session
    user_id = conn.assigns.current_user.id
    # get date for inserted_at, updated_at
    timestamp = DateTime.utc_now() |> DateTime.truncate(:second)
    # generate a list of map of the params for the setting changes
    Enum.map(params, fn {key, value} ->
      %{
        key: key,
        value: value,
        user_id: user_id,
        inserted_at: timestamp,
        updated_at: timestamp
      }
    end)
    |> Tpn.Settings.insert_setting()

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event(
        "",
        "success",
        "Updated successfully."
      )
    )
    |> send_resp(204, "")
  end
end
