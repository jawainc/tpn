defmodule Tpn.Repo.Migrations.CreateTableSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :key, :string, null: false
      add :value, :text
      add :user_id, references(:users, on_delete: :nilify_all), null: true
      timestamps()
    end

    create index(:settings, [:key], unique: true)
  end
end
