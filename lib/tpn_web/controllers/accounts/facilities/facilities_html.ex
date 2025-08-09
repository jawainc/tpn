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
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :lhns, :list, default: [], doc: "the list of local health networks"
  attr :current_user, :map, default: %{}, doc: "the current user"
  def data_form(assigns)

  def get_url, do: @url
end
