defmodule Tpn.Repo.Migrations.AddUnitTypesTable do
  use Ecto.Migration

  def change do
    create table(:unit_types) do
      add :name, :string

      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:unit_types, [:name])
  end
end
