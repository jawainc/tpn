defmodule Tpn.Repo.Migrations.AddFillingMethodsTable do
  use Ecto.Migration

  def change do
    create table(:filling_methods) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:filling_methods, [:name])
  end
end
