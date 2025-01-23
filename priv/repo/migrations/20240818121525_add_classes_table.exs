defmodule Tpn.Repo.Migrations.AddClassesTable do
  use Ecto.Migration

  def change do
    create table(:classes) do
      add :name, :string
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:classes, [:name])
  end
end
