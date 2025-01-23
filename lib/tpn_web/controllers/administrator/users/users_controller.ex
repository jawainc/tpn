defmodule TpnWeb.Administrator.UsersController do
  use TpnWeb, :controller

  alias Tpn.Accounts.Administartors
  alias Tpn.Accounts.Administrator
  alias TpnWeb.Helpers.ClientEvents

  def index(conn, params) do
    with {:ok, {users, meta}} <- Administartors.list_administrators(params) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, users: users)
    end
  end

  def new(conn, _params) do
    conn
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"administrator" => params}) do
    case Administartors.create_administrator(params) do
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
    administrator = Administartors.get_administrator!(id)
    changeset = Administartors.change_administrator(administrator)

    conn
    |> render(:edit, user: administrator, changeset: changeset)
  end

  def update(conn, %{"id" => id, "administrator" => params}) do
    administrator = Administartors.get_administrator!(id)

    case Administartors.update_administrator(administrator, params) do
      {:ok, user} ->
        changeset = Administartors.change_administrator(administrator)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> render(:edit, user: user, changeset: changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:edit, user: administrator, changeset: changeset)
    end
  end

  def change_password(conn, %{"id" => id}) do
    administrator = Administartors.get_administrator!(id)
    changeset = Administartors.change_password(administrator)

    conn
    |> render(:change_password, user: administrator, changeset: changeset)
  end

  def update_password(conn, %{"id" => id, "administrator" => params}) do
    administrator = Administartors.get_administrator!(id)

    case Administartors.update_password(administrator, params) do
      {:ok, user} ->
        changeset = Administartors.change_password(administrator)

        conn
        |> put_flash(:info, "Updated successfully.")
        |> render(:change_password, user: user, changeset: changeset)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> render(:change_password, user: administrator, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    administrator = Administartors.get_administrator!(id)
    {:ok, _administrator} = Administartors.delete_administrator(administrator)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(200, "")
  end

  defp new_change() do
    Administartors.change_administrator(%Administrator{})
  end
end
