defmodule TpnApi.Repo.Migrations.CreateLocalHealthNetworks do
  use Ecto.Migration

  def change do
    create table(:local_health_networks) do
      add :name, :string
      add :code, :string

      timestamps()
    end
    create unique_index(:local_health_networks, [:name, :code], name: :local_health_networks_name_code_index)
  end
end
