defmodule TpnWeb.FillingMethodsController do
  use TpnWeb, :controller

  alias Tpn.FillingMethod
  alias Tpn.FillingMethods
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- FillingMethods.list_filling_methods(params) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: records)
    end
  end

  def new(conn, _params) do
    render(conn, :new, changeset: new_change())
  end

  def create(conn, %{"filling_method" => params}) do
    params = Networks.params_assign_user(conn, params)

    case FillingMethods.create_filling_method(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = FillingMethods.get_filling_method!(id)
    changeset = FillingMethods.change_filling_method(record)
    render(conn, :edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "filling_method" => params}) do
    params = Networks.params_assign_user(conn, params)
    record = FillingMethods.get_filling_method!(id)

    case FillingMethods.update_filling_method(record, params) do
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
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = FillingMethods.get_filling_method!(id)

    {:ok, _} = FillingMethods.delete_filling_method(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change do
    FillingMethods.change_filling_method(%FillingMethod{})
  end
end
