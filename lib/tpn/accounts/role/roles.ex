defmodule Tpn.Accounts.Roles do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Helpers.PaginationHelper
  alias Tpn.Accounts.Role

  def list_roles(params \\ %{}) do
    roles =
      from(a in Role)
      |> PaginationHelper.build_query_params(Role, params)
      |> Tpn.Repo.all()

    meta =
      from(a in Role)
      |> PaginationHelper.get_paging_meta(params, Role)

    {:ok, {roles, meta}}
  end

  def get_role!(id), do: Repo.get!(Role, id)

  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  def delete_role(%Role{} = role) do
    Repo.delete(role)
  end

  def change_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end
end
