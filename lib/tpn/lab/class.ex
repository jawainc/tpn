defmodule Tpn.Class do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name]
  @sortable_fields [:name]

  schema "classes" do
    field :name, :string
    belongs_to :user, Tpn.Accounts.User

    has_many :formularies, Tpn.Formulary

    timestamps(type: :utc_datetime)
  end

  def changeset(class, attrs) do
    class
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
