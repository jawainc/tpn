defmodule TpnWeb.ClassesController do
  use TpnWeb, :controller

  alias Tpn.Class
  alias Tpn.Classes
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- Classes.list_classes(params) do
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

  def create(conn, %{"class" => params}) do
    params = Networks.params_assign_user(conn, params)

    case Classes.create_class(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Classes.get_class!(id)
    changeset = Classes.change_class(record)
    render(conn, :edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "class" => params}) do
    params = Networks.params_assign_user(conn, params)
    record = Classes.get_class!(id)

    case Classes.update_class(record, params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "reloadDataTable",
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
    record = Classes.get_class!(id)

    {:ok, _} = Classes.delete_class(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change, do: Classes.change_class(%Class{})
end
