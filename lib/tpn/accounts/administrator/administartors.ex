defmodule Tpn.Accounts.Administartors do
  import Ecto.Query, warn: false

  alias Tpn.Accounts.Administrator
  alias Tpn.Helpers.PaginationHelper

  alias Tpn.Repo

  def get_administrator_by_login_id_and_password(login_id, password) do
    administrator = Tpn.Repo.get_by(Administrator, login_id: login_id)
    if Administrator.valid_password?(administrator, password), do: administrator
  end

  def list_administrators(params) do
    users =
      from(a in Administrator)
      |> PaginationHelper.build_query_params(Administrator, params)
      |> Tpn.Repo.all()

    meta =
      from(a in Administrator)
      |> PaginationHelper.get_paging_meta(params, Administrator)

    {:ok, {users, meta}}
  end

  def get_administrator!(id), do: Repo.get!(Administrator, id)

  def create_administrator(attrs \\ %{}) do
    %Administrator{}
    |> Administrator.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_administrator(%Administrator{} = user, attrs \\ %{}) do
    user
    |> Administrator.update_changeset(attrs)
    |> Repo.update()
  end

  def update_password(%Administrator{} = user, attrs \\ %{}) do
    user
    |> Administrator.password_changeset(attrs)
    |> Repo.update()
  end

  def delete_administrator(%Administrator{} = user) do
    Repo.delete(user)
  end

  def change_administrator(%Administrator{} = user, attrs \\ %{}) do
    Administrator.registration_changeset(user, attrs)
  end

  def change_password(%Administrator{} = user, attrs \\ %{}) do
    Administrator.password_changeset(user, attrs)
  end
end
