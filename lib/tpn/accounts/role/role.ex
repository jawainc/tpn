defmodule Tpn.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name]
  @sortable_fields [:name]

  schema "roles" do
    field :name, :string
    field :is_admin, :boolean, default: false
    field :is_verifier, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :is_admin, :is_verifier])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
