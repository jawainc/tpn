defmodule Tpn.Accounts.Context.Context do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name, :table]
  @sortable_fields [:name, :table]

  schema "contexts" do
    field :name, :string
    field :table, :string

    timestamps()
  end

  @doc false
  def changeset(context, attrs) do
    context
    |> cast(attrs, [:name, :table])
    |> validate_required([:name, :table])
    |> unique_constraint(:name, name: :context_name_index)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
