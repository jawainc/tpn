defmodule TpnWeb.Administrator.ContextsHTML do
  use TpnWeb, :html

  @url "/administrator/contexts"

  embed_templates "contexts_html/*"

  @doc """
  Renders a form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  def data_form(assigns)

  def get_url, do: @url
end
