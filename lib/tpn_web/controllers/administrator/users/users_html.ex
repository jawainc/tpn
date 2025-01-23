defmodule TpnWeb.Administrator.UsersHTML do
  use TpnWeb, :html

  @url "/administrator/users"

  embed_templates "users_html/*"

  @doc """
  Renders a form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  def user_form(assigns)

  def get_url, do: @url
end
