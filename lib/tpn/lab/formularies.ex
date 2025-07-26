defmodule Tpn.Formularies do
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Tpn.Repo
  alias Tpn.{Formulary, FormularyView, FormularyIngredient, FormularyPatientType}
  alias Tpn.Helpers.PaginationHelper

  def list_formularies(params, conn) do
    formularies =
      from(a in FormularyView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.build_query_params(FormularyView, params, !conn.assigns[:is_admin])
      |> Repo.all()

    meta =
      from(a in FormularyView)
      |> PaginationHelper.build_networks_query(conn)
      |> PaginationHelper.get_paging_meta(params, FormularyView)

    {:ok, {formularies, meta}}
  end

  def formularies_for_select do
    Repo.all(Formulary)
    |> Enum.map(&{&1.name, &1.id})
  end

  def formularies_for_select_by_class_and_patient_type(patient_type_id, class_id) do
    query =
      from f in Formulary,
        join: fpt in FormularyPatientType,
        on: f.id == fpt.formulary_id,
        where: fpt.patient_type_id == ^patient_type_id,
        preload: [:patient_types]

    query
    |> where([f], f.class_id == ^class_id)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def create_formulary(params) do
    multi =
      Multi.new()
      |> Multi.insert(:formulary, %Formulary{} |> Formulary.changeset(params))
      |> parse_patient_types(params)
      |> parse_ingredients(params)

    case Repo.transaction(multi) do
      {:ok, %{formulary: formulary} = _} ->
        {:ok, formulary}

      {:error, changeset} ->
        {:error, changeset}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def get_formulary!(id) do
    Repo.get!(Formulary, id)
  end

  def get_formulary_for_edit(id) do
    Repo.get(Formulary, id)
    |> Repo.preload([:formulary_patient_types, :ingredients])
  end

  def list_enteral_products_for_patient_type(patient_type_id) do
    query =
      from f in Formulary,
        join: fpt in FormularyPatientType,
        on: f.id == fpt.formulary_id,
        where: fpt.patient_type_id == ^patient_type_id,
        preload: [:patient_types]

    query
    |> where([f], f.is_enteral == true)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def list_formularies_for_classes(class_ids) do
    formularies = Repo.all(from f in FormularyView,
      where: f.class_id in ^class_ids
    )
    # get formularies ids
    formulary_ids = Enum.map(formularies, & &1.id)
    ingredients = list_ingredients_for_formularies(formulary_ids)

    Enum.map(formularies, fn formulary ->
      %{
        id: formulary.id,
        name: formulary.name,
        code: formulary.code,
        label_friendly_name: formulary.label_friendly_name,
        is_enteral: formulary.is_enteral,
        concentration: formulary.concentration,
        calories: formulary.calories,
        cost_per_container: formulary.cost_per_container,
        container_size: formulary.container_size,
        print_on_label: formulary.print_on_label,
        include_in_overfill: formulary.include_in_overfill,
        universal_fluid: formulary.universal_fluid,
        class_id: formulary.class_id,
        class_name: formulary.class_name,
        concentration_unit_name: formulary.concentration_unit_name,
        calories_unit_name: formulary.calories_unit_name,
        uom_unit_name: formulary.uom_unit_name,
        solution_type_name: formulary.solution_type_name,
        ingredients: Enum.filter(ingredients, fn ingredient -> ingredient.formulary_id == formulary.id end)
      }
    end)
  end

  def list_ingredients_for_formularies(formulary_ids) do
    Repo.all(from f in FormularyIngredient,
      where: f.formulary_id in ^formulary_ids,
      distinct: [f.formulary_id]
    )
    |> Repo.preload([:ingredient, :unit])
    |> Enum.map(fn fi ->
      %{
        amount: fi.amount,
        formulary_id: fi.formulary_id,
        name: fi.ingredient.name,
        unit_name: fi.unit.unit,
        print_on_label: fi.ingredient.print_on_label
      }
    end)
    |> IO.inspect()
  end

  def change_formulary(formulary) do
    Formulary.changeset(formulary, %{})
  end

  def update_formulary(id, params) do
    formulary = get_formulary!(id)

    multi =
      Multi.new()
      |> Multi.update(:formulary, formulary |> Formulary.changeset(params))
      |> Multi.delete_all(
        :patient_types_deleted,
        fn %{formulary: formulary} ->
          FormularyPatientType
          |> where([fpt], fpt.formulary_id == ^formulary.id)
        end,
        skip: true
      )
      |> Multi.delete_all(
        :ingredients_deleted,
        fn %{formulary: formulary} ->
          FormularyIngredient
          |> where([fi], fi.formulary_id == ^formulary.id)
        end,
        skip: true
      )
      |> parse_patient_types(params)
      |> parse_ingredients(params)

    case Repo.transaction(multi) do
      {:ok, %{formulary: formulary} = _} ->
        {:ok, formulary}

      {:error, changeset} ->
        {:error, changeset}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_formulary(formulary) do
    Repo.delete(formulary)
  end

  defp parse_patient_types(multi, %{"patient_types" => ""} = _params), do: multi

  defp parse_patient_types(multi, %{"patient_types" => types} = _params) do
    patient_types =
      types
      |> String.split(",")
      |> Enum.map(fn x -> String.to_integer(x) end)

    Multi.insert_all(multi, :patient_types, FormularyPatientType, fn %{formulary: formulary} ->
      patient_types
      |> Enum.uniq()
      |> Enum.map(fn id ->
        %{
          formulary_id: formulary.id,
          patient_type_id: id
        }
      end)
    end)
  end

  defp parse_patient_types(multi, _), do: multi

  defp parse_ingredients(multi, %{"ingredients" => ingred} = _params) do
    ingredients =
      ingred
      |> Enum.map(fn {ingredient_id, data} ->
        %{
          ingredient_id: String.to_integer(ingredient_id),
          amount: Float.parse(data["amount"]) |> elem(0),
          unit_id: String.to_integer(data["unit_id"])
        }
      end)

    Multi.insert_all(multi, :ingredients, FormularyIngredient, fn %{formulary: formulary} ->
      ingredients
      |> Enum.map(fn %{ingredient_id: ingredient_id, amount: amount, unit_id: unit_id} ->
        %{
          formulary_id: formulary.id,
          ingredient_id: ingredient_id,
          amount: amount,
          unit_id: unit_id
        }
      end)
    end)
  end

  defp parse_ingredients(multi, _), do: multi
end
