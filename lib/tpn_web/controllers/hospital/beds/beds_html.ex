defmodule TpnWeb.BedsHTML do
  use TpnWeb, :html

  @url "/beds"

  embed_templates "beds_html/*"

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
  attr :wards, :list, default: []
  attr :beds, :list, default: []
  attr :rooms, :list, default: []
  attr :lhns, :list, default: []
  attr :facilities, :list, default: []
  attr :campuses, :map, default: %{}
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
