defmodule Tpn.Patient do
  use Ecto.Schema
  import Ecto.Changeset

  @filterable_fields [:first_name, :last_name, :identity_no, :phone, :email]
  @sortable_fields [:first_name, :last_name, :identity_no, :phone, :email]

  schema "patients" do
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
    field :cancelled, :boolean, default: false

    belongs_to :local_health_network, Tpn.Accounts.Networks.LocalHealthNetwork
    belongs_to :facility, Tpn.Accounts.Networks.Facility
    belongs_to :campus, Tpn.Accounts.Networks.Campus
    belongs_to :user, Tpn.Accounts.User

    has_many :admissions, Tpn.Admission
    has_many :patient_mrns, Tpn.PatientMrn

    timestamps(type: :utc_datetime)
  end

  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :first_name,
      :last_name,
      :identity_no,
      :dob,
      :tpn_id,
      :cancelled,
      :gender,
      :address_1,
      :address_2,
      :city,
      :state,
      :country,
      :zip,
      :phone,
      :email,
      :notes,
      :local_health_network_id,
      :facility_id,
      :campus_id,
      :user_id
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :tpn_id,
      :dob
    ])
    |> validate_dob(:dob)
    |> validate_format(:email, ~r/^[A-Za-z0-9\._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}$/)
  end

  def get_genders() do
    [
      "Male",
      "Female",
      "Other"
    ]
  end

  defp validate_dob(changeset, field) do
    validate_change(changeset, field, fn _field, value ->
      cond do
        Date.compare(value, Date.utc_today()) == :gt -> [{field, "cannot not be in future"}]
        true -> []
      end
    end)
  end

  def filter_fields do
    @filterable_fields
  end

  def sortable_fields do
    @sortable_fields
  end
end
