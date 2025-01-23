defmodule Tpn.Accounts.Networks.Campuses do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Helpers.PaginationHelper
  alias Tpn.Accounts.Networks.Campus

  def list_campuses(params \\ %{}) do
    campuses =
      from(a in Campus)
      |> PaginationHelper.build_query_params(Campus, params)
      |> preload(:facility)
      |> Repo.all()

    meta =
      from(a in Campus)
      |> PaginationHelper.get_paging_meta(params, Campus)

    {:ok, {campuses, meta}}
  end

  def get_campus!(id), do: Repo.get!(Campus, id)

  def create_campus(attrs \\ %{}) do
    %Campus{}
    |> Campus.changeset(attrs)
    |> Repo.insert()
  end

  def update_campus(%Campus{} = campus, attrs) do
    campus
    |> Campus.changeset(attrs)
    |> Repo.update()
  end

  def delete_campus(%Campus{} = campus) do
    Repo.delete(campus)
  end

  def change_campus(%Campus{} = campus, attrs \\ %{}) do
    Campus.changeset(campus, attrs)
  end
end
