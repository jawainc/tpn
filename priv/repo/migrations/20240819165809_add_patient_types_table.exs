defmodule Tpn.Repo.Migrations.AddPatientTypesTable do
  use Ecto.Migration

  def change do
    create table(:patient_types) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:patient_types, [:name])
  end
end
