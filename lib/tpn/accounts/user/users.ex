defmodule Tpn.Accounts.Users do
  import Ecto.Query, warn: false

  alias Tpn.Accounts.{User, UsersRoles}
  alias Tpn.Helpers.PaginationHelper

  alias Tpn.Repo

  def get_user_by_email_and_password(email, password) do
    user =
      User
      |> where([a], a.email == ^email)
      |> where([a], a.deleted == false)
      |> where([a], a.active == true)
      |> Repo.one()
      |> Repo.preload(:role)

    if User.valid_password?(user, password), do: user
  end

  def list_users_for_admin(params) do
    users =
      from(a in User)
      |> PaginationHelper.build_query_params(User, params)
      |> preload([:role])
      |> Tpn.Repo.all()

    meta =
      from(a in User)
      |> PaginationHelper.get_paging_meta(params, User)

    {:ok, {users, meta}}
  end

  def list_users(params) do
    users =
      from(a in UsersRoles)
      |> PaginationHelper.build_query_params(UsersRoles, params)
      |> Tpn.Repo.all()

    meta =
      from(a in UsersRoles)
      |> PaginationHelper.get_paging_meta(params, UsersRoles)

    {:ok, {users, meta}}
  end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs \\ %{}) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def update_password(%User{} = user, attrs \\ %{}) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    # soft delete
    user
    |> User.update_changeset(%{"deleted" => true})
    |> Repo.update()
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  def change_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
  end
end
