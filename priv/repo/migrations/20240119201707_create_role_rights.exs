defmodule TpnApi.Repo.Migrations.CreateRoleRights do
  use Ecto.Migration

  def change do
    create table(:role_rights) do
      add :create, :boolean, default: false, null: false
      add :update, :boolean, default: false, null: false
      add :read, :boolean, default: false, null: false
      add :delete, :boolean, default: false, null: false
      add :role_id, references(:roles), null: false
      add :context_id, references(:contexts),  null: false

      timestamps()
    end
    create unique_index(:role_rights, [:role_id, :context_id])
  end
end
