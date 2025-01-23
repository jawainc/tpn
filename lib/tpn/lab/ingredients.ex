defmodule Tpn.Lab.Ingredients do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Lab.{Ingredient, IngredientsView}
  alias Tpn.Helpers.PaginationHelper

  def list_ingredients(params, conn) do
    ingredients =
      from(a in IngredientsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(IngredientsView, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in IngredientsView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, IngredientsView)

    {:ok, {ingredients, meta}}
  end

  def ingredients_for_select do
    Repo.all(Ingredient)
    |> Enum.map(&{&1.name, &1.id})
  end

  def ingredients_for_select_by_type(type_id) do
    id = String.to_integer(type_id)

    Repo.all(from(i in Ingredient, where: i.unit_type_id == ^id))
  end

  def create_ingredient(params) do
    %Ingredient{}
    |> Ingredient.changeset(params)
    |> Repo.insert()
  end

  def get_ingredient!(id) do
    Repo.get!(Ingredient, id)
  end

  def change_ingredient(ingredient) do
    Ingredient.changeset(ingredient, %{})
  end

  def update_ingredient(ingredient, params) do
    ingredient
    |> Ingredient.changeset(params)
    |> Repo.update()
  end

  def delete_ingredient(ingredient) do
    Repo.delete(ingredient)
  end
end
