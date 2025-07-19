defmodule TpnWeb.Hospital.OrdersController do
  use TpnWeb, :controller

  import Ecto.Query, warn: false

  alias Tpn.{
    Orders,
    Order,
    Patients,
    Admissions,
    VascularAccesses,
    Formularies,
    Templates,
    TemplateProducts,
    Classes
  }

  def index(conn, params) do
    records = Orders.list_orders_by_patient_id(params["patient_id"])
    render(conn, :list, records: records)
  end

  # create order
  def new(conn, %{"patient_id" => patient_id}) do
    admission = Admissions.get_admission_view_by_patient_id(patient_id)
    formularies = Formularies.list_enteral_products_for_patient_type(admission.patient_type_id)
    vascular_accesses = VascularAccesses.vascular_accesses_for_select()
    templates = Templates.list_templates_for_patient_type(admission.patient_type_id)

    conn
    |> assign(:patient_id, patient_id)
    |> assign(:patient, Patients.get_patient_view!(patient_id))
    |> assign(:admission, admission)
    |> assign(:vascular_accesses, vascular_accesses)
    |> assign(:formularies, formularies)
    |> assign(:templates, templates)
    |> assign(:changeset, Order.changeset(%Order{}, %{}))
    |> render(:new)
  end

  def template_products(conn, %{"order" => %{"template_id" => ""}}) do
    render(conn, :template_products, layout: false)
  end

  def template_products(conn, %{"order" => %{"template_id" => id}}) do
    template = Templates.get_template_view!(id)
    patient_type_id = template.patient_type_id
    # get classes and their formularies based on patient type
    classe_data = Classes.classes_with_formularies_for_patient_type(patient_type_id)
    productsList = TemplateProducts.list_template_products_for_order(id)
    # convert products to json
    products = Enum.map(productsList, fn product ->
      %{
        id: product.id,
        dose: product.dose,
        additional_dose: product.additional_dose,
        additional_dose_allowed: product.additional_dose_allowed,
        max_allowed_limit: product.max_allowed_limit,
        substance_locked_on_order: product.substance_locked_on_order,
        dose_unit: product.dose_unit,
        additional_dose_unit: product.additional_dose_unit,
        max_allowed_unit: product.max_allowed_unit,
        filling_method_name: product.filling_method_name,
        user_name: product.user_name,
        formulary_name: product.formulary_name,
        formulary_id: product.formulary_id,
        class_name: product.class_name,
        class_id: product.class_id,
        position: product.position
      }
    end)
      |> Jason.encode!()

    classes = Enum.map(classe_data, fn class ->
      %{
        id: class.id,
        name: class.name,
        formularies: Enum.map(class.formularies, fn formulary ->
          %{
            id: formulary.id,
            name: formulary.name
          }
        end)
      }
    end)
      |> Jason.encode!()

    # load template without layout
    conn
    |> assign(:template, template)
    |> assign(:products, products)
    |> assign(:classes, classes)
    |> render(:template_products, layout: false)
  end


end
