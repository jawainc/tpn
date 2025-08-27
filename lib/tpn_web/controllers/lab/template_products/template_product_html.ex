defmodule TpnWeb.TemplateProductHTML do
  use TpnWeb, :html

  @url "/template_products"

  embed_templates "template_product_html/*"

  @doc """
  Renders a form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  attr :is_admin, :boolean, default: false
  attr :can, :map, default: %{}
  attr :current_user, :map, default: %{}
  attr :flash, :map, default: %{}
  attr :templates, :list, default: []
  attr :substances, :list, default: []
  attr :filling_methods, :list, default: []
  attr :dose_units, :list, default: []
  attr :formularies, :list, default: []
  attr :template_id, :integer, default: nil
  def data_form(assigns)

  def get_url, do: @url
end
