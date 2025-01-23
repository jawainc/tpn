defmodule Tpn.Repo.Migrations.AddUnitTypeUnitsTable do
  use Ecto.Migration

  def change do
    create table(:unit_type_units, primary_key: false) do
      add(:unit_id, references(:units, on_delete: :delete_all), primary_key: true)
      add(:unit_type_id, references(:unit_types, on_delete: :delete_all), primary_key: true)
    end
  end
end
