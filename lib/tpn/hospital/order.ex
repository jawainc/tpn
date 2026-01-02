defmodule Tpn.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Order schema for managing TPN orders.

  ## Order Status Workflow

  The order status follows this workflow:
  - **draft**: Order is saved but not submitted for review (can be edited)
  - **pending**: Order is submitted and awaiting reviewer approval
  - **approved**: Order has been approved by a reviewer and can be processed
  - **rejected**: Order has been rejected by a reviewer (may need revision)

  Status transitions:
  - draft -> pending (when user clicks "Create Order")
  - pending -> approved (when reviewer approves)
  - pending -> rejected (when reviewer rejects)
  - rejected -> pending (when user resubmits after revision)
  """

  schema "orders" do
    field :order_type, :string
    field :status, :string
    field :bag_id, :string
    field :order_date, :naive_datetime
    field :copy_order, :boolean, default: false
    field :number_of_bags, :integer, default: 1
    field :enteral_dose, :float
    field :tpn_infusion_type, :string
    field :infusion_duration_type, :string
    field :tpn_infusion_duration_hours, :integer
    field :lipid_infusion_duration_hours, :integer
    field :dosing_weight, :string
    field :template_fluids, :map, default: %{}
    field :template_properties, :map, default: %{}
    field :using_premixed_bag, :boolean, default: false
    field :premixed_bag_batch_number, :string
    field :premixed_bag_expiry, :naive_datetime

    belongs_to :template, Tpn.Template
    belongs_to :formulary, Tpn.Formulary
    belongs_to :vascular_access, Tpn.VascularAccess
    belongs_to :order, Tpn.Order, foreign_key: :copied_from_order_id
    belongs_to :admission, Tpn.Admission
    belongs_to :patient, Tpn.Patient
    belongs_to :user, Tpn.User

    timestamps(type: :utc_datetime)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :order_type,
      :status,
      :copied_from_order_id,
      :bag_id,
      :order_date,
      :copy_order,
      :number_of_bags,
      :enteral_dose,
      :tpn_infusion_type,
      :infusion_duration_type,
      :tpn_infusion_duration_hours,
      :lipid_infusion_duration_hours,
      :dosing_weight,
      :template_fluids,
      :template_properties,
      :using_premixed_bag,
      :premixed_bag_batch_number,
      :premixed_bag_expiry,
      :template_id,
      :formulary_id,
      :vascular_access_id,
      :copied_from_order_id,
      :admission_id,
      :patient_id,
      :user_id
    ])
    |> validate_required([
      :bag_id,
      :order_type,
      :order_date,
      :template_id
    ])
    |> validate_custom_required([
      :vascular_access_id,
      :enteral_dose,
      :tpn_infusion_type,
      :infusion_duration_type,
      :tpn_infusion_duration_hours,
      :lipid_infusion_duration_hours,
      :dosing_weight
    ])
  end

  defp validate_custom_required(changeset, fields) do
    # when order_type is Batch Production then fields are not required
    type = get_field(changeset, :order_type)

    if type == "Batch Production" do
      []
    else
      validate_required(changeset, fields)
    end
  end
end
