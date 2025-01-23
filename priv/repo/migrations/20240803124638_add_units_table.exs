defmodule Tpn.Repo.Migrations.AddUnitsTable do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :unit, :string

      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end
  end
end
