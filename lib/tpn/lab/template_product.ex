defmodule Tpn.TemplateProduct do
  use Ecto.Schema
  import Ecto.Changeset

  schema "template_products" do
    field :position, :integer
    field :dose, :decimal
    field :additional_dose, :decimal
    field :additional_dose_allowed, :boolean
    field :max_allowed_limit, :decimal
    field :substance_locked_on_order, :boolean

    belongs_to :dose_unit, Tpn.Unit
    belongs_to :additional_dose_unit, Tpn.Unit
    belongs_to :max_allowed_unit, Tpn.Unit
    belongs_to :template, Tpn.Template
    belongs_to :filling_method, Tpn.FillingMethod
    belongs_to :user, Tpn.Accounts.User
    belongs_to :formulary, Tpn.Formulary
    belongs_to :class, Tpn.Class

    timestamps(type: :utc_datetime)
  end

  def changeset(template_product, attrs) do
    template_product
    |> cast(attrs, [
      :position,
      :dose,
      :additional_dose,
      :additional_dose_allowed,
      :max_allowed_limit,
      :substance_locked_on_order,
      :dose_unit_id,
      :additional_dose_unit_id,
      :max_allowed_unit_id,
      :template_id,
      :filling_method_id,
      :user_id,
      :formulary_id,
      :class_id
    ])
    |> validate_required([
      :template_id,
      :class_id
    ])
    |> unique_constraint(:formulary_id, name: :template_products_template_class_formulary_index)
  end
end
