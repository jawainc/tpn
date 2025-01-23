defmodule TpnWeb.Networks.LocalHealthNetworksHTML do
  use TpnWeb, :html

  @url "/lhn"

  embed_templates "local_health_networks_html/*"

  @doc """
  Renders a form.
  """

  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  def data_form(assigns)

  def get_url, do: @url
end
