defmodule TpnWeb.FillingMethodsHTML do
  use TpnWeb, :html

  @url "/filling_methods"

  embed_templates "filling_methods_html/*"

  @doc """
  Renders a form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  attr :is_admin, :boolean, default: false
  attr :can, :map, default: %{}
  attr :current_user, :map, default: %{}
  def data_form(assigns)

  def get_url, do: @url
end
