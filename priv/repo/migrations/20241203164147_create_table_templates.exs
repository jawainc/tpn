defmodule Tpn.Repo.Migrations.CreateTableTemplates do
  use Ecto.Migration

  def change do
    create table(:templates) do
      add :name, :string
      add :bag_over_fill_volume, :decimal
      add :lipid_over_fill_volume, :decimal, null: true
      add :active, :boolean, default: false
      add :fluids, :decimal, null: true
      add :pre_mixed_standard, :boolean, default: false
      add :additional_substances_allowed, :boolean, default: false

      add :fluid_unit_id, references(:units, on_delete: :nilify_all)
      add :patient_type_id, references(:patient_types, on_delete: :nilify_all), null: true
      add :user_id, references(:users, on_delete: :nilify_all), null: true
      timestamps()
    end

    execute """
      CREATE OR REPLACE VIEW templates_view AS
      SELECT t.id,
      t.name,
      t.bag_over_fill_volume,
      t.lipid_over_fill_volume,
      t.active,
      t.fluids,
      t.pre_mixed_standard,
      t.additional_substances_allowed,
      t.fluid_unit_id,
      t.patient_type_id,
      t.user_id,
      t.inserted_at,
      t.updated_at,
      fu.unit as fluid_unit,
      pt.name as patient_type_name,
      u.first_name as user_name
      FROM templates t
      LEFT JOIN units fu ON t.fluid_unit_id = fu.id
      LEFT JOIN patient_types pt ON t.patient_type_id = pt.id
      LEFT JOIN users u ON t.user_id = u.id
    """

    create index(:templates, [:name])
  end
end
