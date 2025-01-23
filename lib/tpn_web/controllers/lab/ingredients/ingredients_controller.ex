defmodule TpnWeb.IngredientsController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.Lab.{Ingredients, Ingredient}
  alias Tpn.UnitTypes
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    with {:ok, {records, meta}} <- Ingredients.list_ingredients(params, conn) do
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
    |> assign(:unit_types, UnitTypes.unit_types_for_select())
    |> render(:new, changeset: new_change())
  end

  def create(conn, %{"ingredient" => params}) do
    params = Networks.params_assign_user(conn, params)

    case Ingredients.create_ingredient(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadDataTable")
        )
        |> assign(:unit_types, UnitTypes.unit_types_for_select())
        |> render(:new, changeset: new_change())

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> assign(:unit_types, UnitTypes.unit_types_for_select())
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Ingredients.get_ingredient!(id)
    changeset = Ingredients.change_ingredient(record)

    conn
    |> assign(:unit_types, UnitTypes.unit_types_for_select())
    |> render(:edit, record: record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ingredient" => params}) do
    params = Networks.params_assign_user(conn, params)
    record = Ingredients.get_ingredient!(id)

    case Ingredients.update_ingredient(record, params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Updated successfully.")
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
        |> assign(:unit_types, UnitTypes.unit_types_for_select())
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Ingredients.get_ingredient!(id)
    {:ok, _bed} = Ingredients.delete_ingredient(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp new_change do
    %Ingredient{}
    |> Ingredient.changeset(%{})
  end
end
