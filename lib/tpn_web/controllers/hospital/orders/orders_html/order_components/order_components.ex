defmodule TpnWeb.Orders.OrderComponents do
  import Phoenix.Component

  use Phoenix.Component
  import Phoenix.HTML
  import TpnWeb.CoreComponents

  embed_templates "order_components_html/*"

  @order_types [
    {"Patient Specific", "patient_specific"},
    {"Batch Production", "batch_production"}
  ]

  @tpn_infusion_types [
    {"2 in 1", "2_in_1"},
    {"3 in 1", "3_in_1"}
  ]

  @infusion_duration_type [
    {"Continous", "Continuous"},
    {"Cyclic", "Cyclic"}
  ]

  attr :patient, :map, required: true

  def order_patient_details(assigns)

  attr :admission, :map, required: true

  def order_admission(assigns)

  attr :admission, :map, required: true
  attr :patient, :map, required: true
  def order_side_bar(assigns)

  attr :changeset, :map, required: true
  attr :vascular_accesses, :list, required: true
  attr :formularies, :list, required: true
  attr :patient_id, :integer, required: true
  attr :admission, :map, required: true
  attr :tpn_infusion_types, :list, default: @tpn_infusion_types
  attr :infusion_duration_type, :list, default: @infusion_duration_type
  attr :templates, :list, required: true
  def order_form_new(assigns)

  def format_lines(nil), do: ""

  def format_lines(string) do
    String.replace(string, "\n", "<br>")
  end

  def format_date(nil), do: ""

  def format_date(date) do
    {:ok, formatted_date} = Timex.format(date, "{M}/{D}/{YYYY} {h12}:{m} {AM}")
    formatted_date
  end
end
