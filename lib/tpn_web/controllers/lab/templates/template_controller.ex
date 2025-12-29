defmodule TpnWeb.TemplateController do
  use TpnWeb, :controller
  import Ecto.Query, warn: false

  alias Tpn.{Template, Templates, TemplateProducts}
  alias Tpn.PatientTypes
  alias Tpn.Units
  alias Tpn.Settings
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  @fluid_unit_type "template_fluid_unit_type"

  def index(conn, params) do
    with {:ok, {records, meta}} <- Templates.list_templates(params, conn) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: records)
    end
  end

  def show(conn, %{"id" => id}) do
    record = Templates.get_template_view!(id)
    products = TemplateProducts.get_template_products_by_template_id(id)

    conn
    |> assign(:record, record)
    |> assign(:products, products)
    |> render(:show)
  end

  def new(conn, _params) do
    conn
    |> set_assigns()
    |> assign(:changeset, new_change())
    |> render(:new)
  end

  def create(conn, %{"template" => template_params}) do
    params = Networks.params_assign_user(conn, template_params)

    case Templates.create_template(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "created successfully.")
        |> set_assigns()
        |> assign(:changeset, new_change())
        |> render(:new)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> set_assigns()
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = Templates.get_template!(id)
    changeset = Templates.change_template(record)

    conn
    |> set_assigns()
    |> assign(:changeset, changeset)
    |> assign(:record, record)
    |> render(:edit)
  end

  def update(conn, %{"id" => id, "template" => template_params}) do
    params = Networks.params_assign_user(conn, template_params)
    record = Templates.get_template!(id)

    case Templates.update_template(record, params) do
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
        |> set_assigns()
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    record = Templates.get_template!(id)
    {:ok, _template} = Templates.delete_template(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event("reloadDataTable", "success", "Deleted successfully.")
    )
    |> send_resp(204, "")
  end

  defp set_assigns(conn) do
    settings = get_settings()
    fluid_units = Units.units_by_type_for_select(settings[@fluid_unit_type])

    conn
    |> assign(:fluid_units, fluid_units)
    |> assign(:patient_types, PatientTypes.patient_types_for_select())
  end

  defp new_change do
    %Template{}
    |> Template.changeset(%{})
  end

  defp get_settings() do
    Settings.get_settings()
    |> Enum.map(&{&1.key, &1.value})
    |> Enum.into(%{})
  end
end
