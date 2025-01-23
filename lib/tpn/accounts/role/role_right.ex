defmodule Tpn.Accounts.RoleRight do
  use Ecto.Schema
  import Ecto.Changeset

  schema "role_rights" do
    field :delete, :boolean, default: false
    field :update, :boolean, default: false
    field :read, :boolean, default: false
    field :create, :boolean, default: false

    belongs_to :context, Tpn.Accounts.Context.Context
    belongs_to :role, Tpn.Accounts.Role.Role

    timestamps()
  end

  @doc false
  def changeset(role_rights, attrs) do
    role_rights
    |> cast(attrs, [:create, :update, :read, :delete, :role_id, :context_id])
    |> validate_required([:role_id, :context_id])
  end
end
