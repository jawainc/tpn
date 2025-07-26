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
    Classes,
    FillingMethods,
    Settings
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
    {class_ids, classes} = classes(template.patient_type_id)
    currency = get_currency()
    # load template without layout
    conn
    |> assign(:template, template)
    |> assign(:products, template_products(id))
    |> assign(:classes, classes)
    |> assign(:filling_methods, filling_methods())
    |> assign(:formularies, formularies(class_ids))
    |> assign(:currency, currency)
    |> render(:template_products, layout: false)
  end

  defp filling_methods do
    FillingMethods.filling_methods()
    |> Jason.encode!()
  end

  defp template_products(id) do
    TemplateProducts.list_template_products_for_order(id)
    |> Jason.encode!()
  end

  defp classes(patient_type_id) do
    classes = Classes.classes_with_formularies_for_patient_type(patient_type_id)
    {Enum.map(classes, fn class -> class.id end), Jason.encode!(classes)}
  end

  defp formularies(class_ids) do
    Formularies.list_formularies_for_classes(class_ids)
    |> Jason.encode!()
    |> IO.inspect()
  end

  defp get_currency() do
    currency = Settings.get_settings()
      |> Enum.find(fn setting -> setting.key == "currency" end)
      |> Map.get(:value)

    code = Jason.decode!(currency)
      |> Map.get("code")

    symbol = Jason.decode!(currency)
      |> Map.get("symbol")

    %{:code => code, :symbol => symbol}
    |> Jason.encode!()
  end


end
