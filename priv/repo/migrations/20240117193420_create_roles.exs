defmodule TpnApi.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string, null: false
      add :is_admin, :boolean, default: false, null: false
      add :is_verifier, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:roles, [:name])
  end
end
