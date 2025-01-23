defmodule Tpn.Hospital.Bed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "beds" do
    field :name, :string
    field :code, :string

    belongs_to :local_health_network, Tpn.Accounts.Networks.LocalHealthNetwork
    belongs_to :facility, Tpn.Accounts.Networks.Facility
    belongs_to :campus, Tpn.Accounts.Networks.Campus
    belongs_to :ward, Tpn.Ward
    belongs_to :room, Tpn.Room
    belongs_to :user, Tpn.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(bed, attrs) do
    bed
    |> cast(attrs, [
      :name,
      :code,
      :local_health_network_id,
      :facility_id,
      :campus_id,
      :ward_id,
      :room_id,
      :user_id
    ])
    |> validate_required([
      :name,
      :code,
      :ward_id,
      :room_id,
      :user_id
    ])
  end
end
