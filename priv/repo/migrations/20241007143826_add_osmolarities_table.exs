defmodule Tpn.Repo.Migrations.AddOsmolaritiesTable do
  use Ecto.Migration

  def change do
    create table(:osmolarities) do
      add :name, :string
      add :unit_id, references(:units, on_delete: :nilify_all), null: true
      add :vascular_access_id, references(:vascular_accesses, on_delete: :nilify_all), null: true
      add :patient_type_id, references(:patient_types, on_delete: :nilify_all), null: true
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:osmolarities, [:name])
  end
end
