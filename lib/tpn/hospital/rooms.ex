defmodule Tpn.Hospital.Rooms do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Hospital.{RoomsView, Room}
  alias Tpn.Helpers.PaginationHelper

  def list_rooms(params, conn) do
    users =
      from(a in RoomsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(RoomsView, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in RoomsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, RoomsView)

    {:ok, {users, meta}}
  end

  def create_room(params) do
    %Room{}
    |> Room.changeset(params)
    |> Repo.insert()
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  def change_room(room) do
    Room.changeset(room, %{})
  end

  def update_room(room, params) do
    room
    |> Room.changeset(params)
    |> Repo.update()
  end

  def delete_room(room) do
    Repo.delete(room)
  end
end
