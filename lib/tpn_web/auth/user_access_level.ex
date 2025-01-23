defmodule TpnWeb.Auth.UserAccessLevel do
  import Ecto.Query, warn: false
  alias Tpn.Repo

  alias Tpn.Accounts.RoleRight

  def generate_role_rights(role_id) do
    rights =
      Repo.all(
        from rr in RoleRight,
          where: rr.role_id == ^role_id
      )
      |> Repo.preload(:context)

    Enum.scan(rights, %{}, fn right, acc ->
      acc
      |> Map.put(:context, right.context.table)
      |> Map.put(:name, right.context.name)
      |> Map.put(:create, right.create)
      |> Map.put(:update, right.update)
      |> Map.put(:read, right.read)
      |> Map.put(:delete, right.delete)
    end)
  end

  def has_menu_access_level?(_, true, _), do: true

  def has_menu_access_level?(user_access_level, _, items) do
    case Enum.empty?(user_access_level) do
      true ->
        false

      _ ->
        Enum.reduce_while(user_access_level, false, fn level, acc ->
          if acc,
            do: {:halt, acc},
            else:
              {:cont,
               Enum.find_value(items, fn item ->
                 case item == level.name do
                   true -> level.read
                   _ -> false
                 end
               end)}
        end)
    end
  end
end
