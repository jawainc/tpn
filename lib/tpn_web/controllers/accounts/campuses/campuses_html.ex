defmodule TpnWeb.CampusesHTML do
  use TpnWeb, :html

  @url "/campuses"

  embed_templates "campuses_html/*"

  @doc """
  Renders a form.
  """

  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  attr :facilities, :list, default: [], doc: "the list of facilities"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  def data_form(assigns)

  def get_url, do: @url
end
