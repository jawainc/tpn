defmodule Tpn.Hospital.Ward do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:name, :code, :local_health_network, :facility, :campus, :user_name]
  @sortable_fields [:name, :code, :local_health_network, :facility, :campus, :user_name]

  schema "wards" do
    field :name, :string
    field :code, :string

    belongs_to :local_health_network, Tpn.Accounts.Networks.LocalHealthNetwork
    belongs_to :facility, Tpn.Accounts.Networks.Facility
    belongs_to :campus, Tpn.Accounts.Networks.Campus
    belongs_to :user, Tpn.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :code, :local_health_network_id, :facility_id, :campus_id, :user_id])
    |> validate_required([
      :name,
      :code,
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
