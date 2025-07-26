defmodule Tpn.FillingMethod do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name, :id]}

  @filterable_fields [:name]
  @sortable_fields [:name]

  schema "filling_methods" do
    field :name, :string
    belongs_to :user, Tpn.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(filling_method, attrs) do
    filling_method
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
