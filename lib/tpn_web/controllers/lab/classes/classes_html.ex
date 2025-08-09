defmodule TpnWeb.ClassesHTML do
  use TpnWeb, :html

  @url "/classes"

  embed_templates "classes_html/*"

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
  def data_form(assigns)

  def get_url, do: @url
end
