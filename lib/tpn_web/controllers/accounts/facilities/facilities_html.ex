defmodule TpnWeb.FacilitiesHTML do
  use TpnWeb, :html

  @url "/facilities"

  embed_templates "facilities_html/*"

  @doc """
  Renders a form.
  """

  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  def data_form(assigns)

  def get_url, do: @url
end
