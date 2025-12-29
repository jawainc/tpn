defmodule TpnWeb.AccountsHTML do
  use TpnWeb, :html

  @url "/users"

  embed_templates "accounts_html/*"

  @doc """
  Renders a form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  def user_form(assigns)

  def get_url, do: @url
end
