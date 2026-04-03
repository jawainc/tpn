defmodule Tpn.Template do
  use Ecto.Schema
  import Ecto.Changeset

  schema "templates" do
    field :name, :string
    field :bag_over_fill_volume, :decimal
    field :lipid_over_fill_volume, :decimal
    field :active, :boolean
    field :fluids, :decimal
    field :pre_mixed_standard, :boolean
    field :additional_substances_allowed, :boolean

    # Calculation-related fields
    field :calculation_config, :map, default: %{}
    field :osmolarity_warning_threshold, :decimal
    field :osmolarity_error_threshold, :decimal

    belongs_to :fluid_unit, Tpn.Unit
    belongs_to :patient_type, Tpn.PatientType
    belongs_to :user, Tpn.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [
      :name,
      :bag_over_fill_volume,
      :lipid_over_fill_volume,
      :active,
      :fluids,
      :pre_mixed_standard,
      :additional_substances_allowed,
      :calculation_config,
      :osmolarity_warning_threshold,
      :osmolarity_error_threshold,
      :fluid_unit_id,
      :patient_type_id,
      :user_id
    ])
    |> validate_required([
      :name,
      :patient_type_id,
      :bag_over_fill_volume,
      :fluid_unit_id
    ])
    |> validate_number(:osmolarity_warning_threshold, greater_than_or_equal_to: 0)
    |> validate_number(:osmolarity_error_threshold, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
