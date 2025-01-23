defmodule Tpn.Repo.Migrations.AddSolutionTypesTable do
  use Ecto.Migration

  def change do
    create table(:solution_types) do
      add :name, :string
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:solution_types, [:name])
  end
end
