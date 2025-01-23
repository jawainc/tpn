defmodule TpnApi.Repo.Migrations.CreateCampuses do
  use Ecto.Migration

  def change do
    create table(:campuses) do
      add :name, :string
      add :code, :string
      add :facility_id, references(:facilities)

      timestamps()
    end

    create unique_index(:campuses, [:name, :code], name: :campuses_name_code_index)
  end
end
