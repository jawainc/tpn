defmodule Tpn.Accounts.UsersRoles do
  use Ecto.Schema

  @filterable_fields [
    :first_name,
    :last_name,
    :email,
    :contact_no,
    :role,
    :local_health_network,
    :facility,
    :campus
  ]
  @sortable_fields [
    :first_name,
    :last_name,
    :email,
    :contact_no,
    :role,
    :local_health_network,
    :facility,
    :campus
  ]

  schema "users_roles" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :contact_no, :string
    field :active, :boolean, default: true
    field :role, :string
    field :role_id, :integer
    field :local_health_network, :string
    field :facility, :string
    field :campus, :string
    field :inserted_at, :utc_datetime
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
