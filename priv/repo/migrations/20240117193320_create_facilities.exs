defmodule TpnApi.Repo.Migrations.CreateFacilities do
  use Ecto.Migration

  def change do
    create table(:facilities) do
      add :name, :string
      add :code, :string
      add :local_health_network_id, references(:local_health_networks)

      timestamps()
    end
    create unique_index(:facilities, [:name, :code], name: :facilities_name_code_index)
  end
end
