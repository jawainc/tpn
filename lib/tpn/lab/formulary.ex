defmodule Tpn.Formulary do
  use Ecto.Schema
  import Ecto.Changeset

  schema "formularies" do
    field :name, :string
    field :label_friendly_name, :string
    field :code, :string
    field :is_enteral, :boolean
    field :concentration, :decimal
    field :calories, :decimal
    field :cost_per_container, :decimal
    field :container_size, :decimal
    field :print_on_label, :boolean
    field :include_in_overfill, :boolean
    field :universal_fluid, :boolean

    belongs_to :class, Tpn.Class
    belongs_to :concentration_unit, Tpn.Unit
    belongs_to :calories_unit, Tpn.Unit
    belongs_to :uom_unit, Tpn.Unit
    belongs_to :solution_type, Tpn.SolutionType
    belongs_to :user, Tpn.Accounts.User

    has_many :ingredients, Tpn.FormularyIngredient
    has_many :formulary_patient_types, Tpn.FormularyPatientType
    has_many :patient_types, through: [:formulary_patient_types, :patient_type]

    timestamps(type: :utc_datetime)
  end

  def changeset(formulary, params \\ %{}) do
    formulary
    |> cast(params, [
      :name,
      :label_friendly_name,
      :code,
      :is_enteral,
      :concentration,
      :calories,
      :cost_per_container,
      :container_size,
      :print_on_label,
      :include_in_overfill,
      :universal_fluid,
      :class_id,
      :concentration_unit_id,
      :calories_unit_id,
      :uom_unit_id,
      :solution_type_id,
      :user_id
    ])
    |> validate_required([
      :name,
      :label_friendly_name,
      :code,
      :class_id,
      :concentration,
      :concentration_unit_id
    ])
  end
end
