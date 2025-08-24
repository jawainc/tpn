defmodule TpnWeb.TemplateProductController do
  use TpnWeb, :controller
  import Ecto.Query, warn: false

  alias Tpn.{TemplateProduct, TemplateProducts}
  alias Tpn.Templates
  alias Tpn.Classes
  alias Tpn.FillingMethods
  alias Tpn.Units
  alias Tpn.Settings
  alias Tpn.Formularies
  alias TpnWeb.Helpers.{ClientEvents, Networks}

  @dose_unit_type "template_dosing_unit_type"

  def index(conn, params) do
    with {:ok, {records, meta}} <- TemplateProducts.list_template_products(params, conn) do
      layout =
        case params["table"] do
          "1" -> :data_table
          _ -> :index
        end

      render(conn, layout, meta: meta, records: records)
    end
  end

  def new(conn, %{"id" => template_id}) do
    conn
    |> set_assigns()
    |> assign(:template_id, template_id)
    |> assign(:formularies, [])
    |> assign(:changeset, new_change())
    |> render(:new)
  end

  def list_template_products(conn, %{"id" => id}) do
    template_products = TemplateProducts.list_template_products_by_template_id(id)
    render(conn, :list, products: template_products, template_id: id)
  end

  def create(conn, %{"template_product" => template_product_params}) do
    params = Networks.params_assign_user(conn, template_product_params)

    case TemplateProducts.create_template_product(params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "created successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event("reloadProductsTable")
        )
        |> set_assigns()
        |> assign(:template_id, params["template_id"])
        |> assign(:formularies, [])
        |> assign(:changeset, new_change())
        |> render(:new)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> set_assigns()
        |> assign(:template_id, params["template_id"])
        |> assign(:formularies, formularies_data(params["template_id"], params["class_id"]))
        |> render(:new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    record = TemplateProducts.get_template_product!(id)
    changeset = TemplateProducts.change_template_product(record)

    conn
    |> set_assigns()
    |> assign(:template_id, record.template_id)
    |> assign(:formularies, formularies_data(record.template_id, record.class_id))
    |> assign(:changeset, changeset)
    |> assign(:record, record)
    |> render(:edit)
  end

  def update(conn, %{"id" => id, "template_product" => template_product_params}) do
    record = TemplateProducts.get_template_product!(id)
    params = Networks.params_assign_user(conn, template_product_params)

    case TemplateProducts.update_template_product(record, params) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Updated successfully.")
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "reloadProductsTable",
            "success",
            "Updated successfully."
          )
        )
        |> send_resp(204, "")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Please fix the errors.")
        |> set_assigns()
        |> assign(:formularies, formularies_data(params["template_id"], params["class_id"]))
        |> render(:edit, record: record, changeset: changeset)
    end
  end

  def sort(conn, %{"products" => products}) do
    TemplateProducts.sort_template_products(products)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event(
        "reloadProductsTable",
        "success",
        "Updated successfully."
      )
    )
    |> send_resp(204, "")
  end

  def delete(conn, %{"id" => id}) do
    record = TemplateProducts.get_template_product!(id)
    {:ok, _} = TemplateProducts.delete_template_product(record)

    conn
    |> put_resp_header(
      "hx-trigger",
      ClientEvents.generate_client_event(
        "reloadProductsTable",
        "success",
        "Deleted successfully."
      )
    )
    |> send_resp(204, "")
  end

  def formularies(conn, %{"class_id" => class_id, "template_id" => template_id} = _params) do
    render(
      conn,
      :formularies,
      data: formularies_data(template_id, class_id),
      select_id: "template_product_formulary_id",
      name: "template_product[formulary_id]"
    )
  end

  def formularies_data(template_id, class_id) do
    template =
      Templates.get_template!(template_id)

    Formularies.formularies_for_select_by_class_and_patient_type(
      template.patient_type_id,
      class_id
    )
  end

  defp set_assigns(conn) do
    settings = get_settings()
    dose_units = Units.units_by_type_for_select(settings[@dose_unit_type])

    conn
    |> assign(:dose_units, dose_units)
    |> assign(:templates, Templates.templates_for_select())
    |> assign(:substances, Classes.classes_for_select())
    |> assign(:filling_methods, FillingMethods.filling_methods_for_select())
  end

  defp new_change do
    %TemplateProduct{}
    |> TemplateProduct.changeset(%{})
  end

  defp get_settings() do
    Settings.get_settings()
    |> Enum.map(&{&1.key, &1.value})
    |> Enum.into(%{})
  end
end
