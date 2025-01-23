defmodule TpnWeb.Administrator.ContextsController do
  use TpnWeb, :controller

  alias Tpn.Accounts.Context.{Contexts, Context}
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {records, meta}} <- Contexts.list_contexts(params) do
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
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"context" => params}) do
    case Contexts.create_context(params) do
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
    context = Contexts.get_context!(id)
    changeset = Contexts.change_context(context)

    conn
    |> render(:edit, record: context, changeset: changeset)
  end

  def update(conn, %{"id" => id, "context" => params}) do
    record = Contexts.get_context!(id)

    case Contexts.update_context(record, params) do
      {:ok, record} ->
        changeset = Contexts.change_context(record)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> render(:edit, record: record, changeset: changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Contexts.get_context!(id)
    {:ok, _context} = Contexts.delete_context(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change() do
    Contexts.change_context(%Context{})
  end
end
