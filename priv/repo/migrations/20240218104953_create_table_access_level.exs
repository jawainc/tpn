defmodule TpnApi.Repo.Migrations.CreateTableAccessLevel do
  use Ecto.Migration

  def change do
    create table(:access_levels) do
      add :access_type, :string
      add :access_id, :bigint
      add :user_id, references(:users)

      timestamps()
    end
    create unique_index(:access_levels, [:user_id], name: :access_levels_user_index)
  end
end
