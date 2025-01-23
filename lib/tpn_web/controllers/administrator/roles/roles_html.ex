defmodule TpnWeb.Administrator.RolesHTML do
  use TpnWeb, :html

  @url "/administrator/roles"

  embed_templates "roles_html/*"

  @doc """
  Renders a form.
  """

  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  def data_form(assigns)

  def get_url, do: @url
end
