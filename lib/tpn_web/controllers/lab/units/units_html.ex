defmodule TpnWeb.UnitsHTML do
  use TpnWeb, :html

  @url "/units"

  embed_templates "units_html/*"

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

  def is_selected?(false, _, _), do: false

  def is_selected?(true, value, types) do
    Enum.member?(types, value)
  end

  def types_value(types) do
    Enum.join(types, ",")
  end
end
