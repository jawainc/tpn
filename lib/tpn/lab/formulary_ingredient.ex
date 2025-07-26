defmodule Tpn.FormularyIngredient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "formulary_ingredients" do
    field :amount, :decimal
    belongs_to :formulary, Tpn.Formulary
    belongs_to :ingredient, Tpn.Lab.Ingredient
    belongs_to :unit, Tpn.Unit
  end

  def changeset(formulary_ingredient, attrs) do
    formulary_ingredient
    |> cast(attrs, [:formulary_id, :ingredient_id, :unit_id, :amount])
    |> validate_required([:formulary_id, :ingredient_id, :unit_id, :amount])
    |> unique_constraint(:formulary_ingredients)
  end
end
