defmodule TpnWeb.RoomsHTML do
  use TpnWeb, :html

  @url "/rooms"

  embed_templates "rooms_html/*"

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

  def netwrok_access(true, _, _), do: true

  def netwrok_access(false, "facility", user) do
    if is_nil(user.facility_id) do
      true
    else
      false
    end
  end

  def netwrok_access(false, "campus", user) do
    if is_nil(user.campus_id) do
      true
    else
      false
    end
  end
end
