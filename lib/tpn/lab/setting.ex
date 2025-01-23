defmodule Tpn.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings" do
    field :key, :string, primary_key: true
    field :value, :string

    belongs_to :user, Tpn.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:key, :value, :user_id])
    |> validate_required([:key])
  end
end
