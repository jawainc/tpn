defmodule TpnWeb.UnitsController do
  use TpnWeb, :controller

  alias Tpn.Unit
  alias Tpn.Units
  alias Tpn.UnitTypes
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- Units.list_units(params, conn) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: records)
    end
  end

  def new(conn, _params) do
    conn
    |> assign(:types, UnitTypes.unit_types())
    |> assign(:selected_types, [])
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"unit" => params}) do
    params = Networks.params_assign_user(conn, params)

    case Units.create(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> assign(:types, UnitTypes.unit_types())
        |> assign(:selected_types, [])
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> assign(:types, UnitTypes.unit_types())
        |> assign(:selected_types, [])
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Units.get_unit_with_types!(id)
    changeset = Units.change_unit(record)
    selected_types = Enum.map(record.types, & &1.id)

    conn
    |> assign(:types, UnitTypes.unit_types())
    |> assign(:selected_types, selected_types)
    |> render(:edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "unit" => params}) do
    params = Networks.params_assign_user(conn, params)

    case Units.update(id, params) do
      {:ok, _} ->
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

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> assign(:types, UnitTypes.unit_types())
        |> assign(
          :selected_types,
          String.split(params["types"], ",") |> Enum.map(&String.to_integer/1)
        )
        |> render(:edit, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Units.get_unit!(id)
    {:ok, _} = Units.delete(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change() do
    Units.change_unit(%Unit{})
  end
end
