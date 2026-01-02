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

  alias TpnWeb.Helpers.{ClientEvents, Networks}

  def index(conn, params) do
    records = Orders.list_orders_by_patient_id(params["patient_id"])
    render(conn, :list, records: records)
  end

  def show(conn, _params) do
    orders = Orders.list_orders()
    render(conn, :show, orders: orders)
  end

  @doc """
  This function is used to get the admissions for the user based on the networks.
  """
  def admissions(conn, _params) do
    case Networks.get_user_network_access(conn) do
      {:ok, %{lhn_id: lhn_id, facility_id: facility_id, campus_id: campus_id}} ->
        {:ok, admissions} = Admissions.list_admissions_for_user(lhn_id, facility_id, campus_id)
        render(conn, :admissions, admissions: admissions)

      {:error, _} ->
        render(conn, :admissions, admissions: [])
    end
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

  def create(conn, %{"order" => order_params} = params) do
    user_id = conn.assigns.current_user.id
    patient_id = params["patient_id"]
    admission_id = params["admission_id"]

    # Generate unique bag_id
    bag_id = generate_bag_id()

    order_attrs =
      order_params
      |> Map.put("user_id", user_id)
      |> Map.put("patient_id", patient_id)
      |> Map.put("admission_id", admission_id)
      |> Map.put("bag_id", bag_id)
      |> Map.put("order_date", NaiveDateTime.utc_now())

    case Orders.create_order(order_attrs) do
      {:ok, order} ->
        status = Map.get(order_attrs, "status", "draft")

        message =
          case status do
            "draft" -> "Order saved as draft successfully"
            "pending" -> "Order created and submitted for review"
            _ -> "Order created successfully"
          end

        conn
        |> put_resp_header(
          "hx-trigger",
          ClientEvents.generate_client_event(
            "",
            "success",
            message
          )
        )
        |> send_resp(204, "")

      {:error, %Ecto.Changeset{} = changeset} ->
        admission = Admissions.get_admission_view_by_patient_id(patient_id)

        formularies =
          Formularies.list_enteral_products_for_patient_type(admission.patient_type_id)

        vascular_accesses = VascularAccesses.vascular_accesses_for_select()
        templates = Templates.list_templates_for_patient_type(admission.patient_type_id)

        conn
        |> assign(:patient_id, patient_id)
        |> assign(:patient, Patients.get_patient_view!(patient_id))
        |> assign(:admission, admission)
        |> assign(:vascular_accesses, vascular_accesses)
        |> assign(:formularies, formularies)
        |> assign(:templates, templates)
        |> assign(:changeset, changeset)
        |> put_flash(:error, "Failed to create order. Please check the form.")
        |> render(:new)
    end
  end

  defp generate_bag_id do
    # Generate a unique bag ID with timestamp
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :rand.uniform(9999)
    "BAG-#{timestamp}-#{random}"
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
    |> Enum.map(&format_product_decimals/1)
    |> Jason.encode!()
  end

  defp format_product_decimals(product) do
    product
    |> Map.update(:dose, nil, &format_decimal_value/1)
    |> Map.update(:volume, nil, &format_decimal_value/1)
    |> Map.update(:fill_volume, nil, &format_decimal_value/1)
    |> Map.update(:additional_dose, nil, &format_decimal_value/1)
    |> Map.update(:max_allowed_limit, nil, &format_decimal_value/1)
  end

  defp classes(patient_type_id) do
    classes = Classes.classes_with_formularies_for_patient_type(patient_type_id)
    {Enum.map(classes, fn class -> class.id end), Jason.encode!(classes)}
  end

  defp formularies(class_ids) do
    Formularies.list_formularies_for_classes(class_ids)
    |> Enum.map(&format_formulary_decimals/1)
    |> Jason.encode!()
  end

  defp format_formulary_decimals(formulary) do
    formulary
    |> Map.update(:concentration, nil, &format_decimal_value/1)
    |> Map.update(:calories, nil, &format_decimal_value/1)
    |> Map.update(:cost_per_container, nil, &format_decimal_value/1)
    |> Map.update(:container_size, nil, &format_decimal_value/1)
    |> format_formulary_ingredients()
  end

  defp format_formulary_ingredients(formulary) do
    case Map.get(formulary, :ingredients) do
      nil ->
        formulary

      ingredients when is_list(ingredients) ->
        formatted_ingredients =
          Enum.map(ingredients, fn ingredient ->
            Map.update(ingredient, :amount, nil, &format_decimal_value/1)
          end)

        Map.put(formulary, :ingredients, formatted_ingredients)

      _ ->
        formulary
    end
  end

  defp format_decimal_value(nil), do: nil
  defp format_decimal_value(value) when is_binary(value), do: value

  defp format_decimal_value(%Decimal{} = value) do
    value
    |> Decimal.to_string()
    |> String.replace(~r/\.?0+$/, "")
  end

  defp format_decimal_value(value), do: value

  defp get_currency() do
    currency =
      Settings.get_settings()
      |> Enum.find(fn setting -> setting.key == "currency" end)
      |> Map.get(:value)

    code =
      Jason.decode!(currency)
      |> Map.get("code")

    symbol =
      Jason.decode!(currency)
      |> Map.get("symbol")

    %{:code => code, :symbol => symbol}
    |> Jason.encode!()
  end
end
