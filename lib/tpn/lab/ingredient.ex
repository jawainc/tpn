defmodule Tpn.Lab.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :print_on_label]}

  @filterable_fields [:name]
  @sortable_fields [:name]

  schema "ingredients" do
    field :name, :string
    field :print_on_label, :boolean, default: false

    belongs_to :unit_type, Tpn.UnitType
    belongs_to :user, Tpn.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [
      :name,
      :unit_type_id,
      :print_on_label,
      :user_id
    ])
    |> validate_required([
      :name,
      :unit_type_id,
      :user_id
    ])
    |> unique_constraint(:name)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
