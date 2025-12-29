defmodule TpnWeb.SolutionTypesController do
  use TpnWeb, :controller

  alias Tpn.SolutionType
  alias Tpn.SolutionTypes
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- SolutionTypes.list_solution_types(params) do
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

  def create(conn, %{"solution_type" => params}) do
    params = Networks.params_assign_user(conn, params)

    case SolutionTypes.create_solution_type(params) do
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
    record = SolutionTypes.get_solution_type!(id)
    changeset = SolutionTypes.change_solution_type(record)
    render(conn, :edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "solution_type" => params}) do
    params = Networks.params_assign_user(conn, params)
    record = SolutionTypes.get_solution_type!(id)

    case SolutionTypes.update_solution_type(record, params) do
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
    record = SolutionTypes.get_solution_type!(id)

    {:ok, _} = SolutionTypes.delete_solution_type(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change do
    SolutionTypes.change_solution_type(%SolutionType{})
  end
end
