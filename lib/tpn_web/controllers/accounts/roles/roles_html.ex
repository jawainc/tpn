defmodule TpnWeb.RolesHTML do
  use TpnWeb, :html

  @url "/roles"

  embed_templates "roles_html/*"

  @doc """
  Renders a form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :edit, :boolean, default: false
  def data_form(assigns)

  def get_url, do: @url

  @doc """
  Returns the role has right or not.
  """
  def has_role_right?(role_rights, context_id, right) do
    cond do
      is_nil(role_rights) ->
        false

      Enum.empty?(role_rights) ->
        false

      true ->
        Enum.any?(role_rights, fn role_right ->
          r_t = role_right |> Map.from_struct()
          r_t.context_id == context_id && r_t[right]
        end)
    end
  end
end
