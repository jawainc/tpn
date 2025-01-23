defmodule Tpn.Repo.Migrations.AddVascularAccessesTable do
  use Ecto.Migration

  def change do
    create table(:vascular_accesses) do
      add :name, :string
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:vascular_accesses, [:name])
  end
end
