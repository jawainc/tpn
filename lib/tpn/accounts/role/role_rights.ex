defmodule Tpn.Accounts.RoleRights do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Tpn.Repo

  alias Tpn.Accounts.RoleRight

  def get_role_rights!(id), do: Repo.get!(RoleRight, id)

  def create_role_rights(attrs \\ %{}) do
    %RoleRight{}
    |> RoleRight.changeset(attrs)
    |> Repo.insert()
  end

  def update_role_rights(%RoleRight{} = role_rights, attrs) do
    role_rights
    |> RoleRight.changeset(attrs)
    |> Repo.update()
  end

  def delete_role_rights(%RoleRight{} = role_rights) do
    Repo.delete(role_rights)
  end

  def change_role_rights(%RoleRight{} = role_rights, attrs \\ %{}) do
    RoleRight.changeset(role_rights, attrs)
  end
end
