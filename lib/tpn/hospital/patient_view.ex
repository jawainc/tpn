defmodule Tpn.PatientView do
  use Ecto.Schema

  @filterable_fields []

  @sortable_fields []

  schema "patients_view" do
    field :first_name, :string
    field :last_name, :string
    field :identity_no, :string
    field :dob, :date
    field :gender, :string
    field :address_1, :string
    field :address_2, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :zip, :string
    field :phone, :string
    field :email, :string
    field :notes, :string
    field :tpn_id, :string
    field :local_health_network, :string
    field :facility, :string
    field :campus, :string
    field :user_name, :string
    field :is_admitted, :boolean
    field :local_health_network_id, :integer
    field :facility_id, :integer
    field :campus_id, :integer
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
