defmodule Tpn.Repo.Migrations.CreateTableTemplateProducts do
  use Ecto.Migration

  def change do
    create table(:template_products) do
      add :position, :integer, null: false, default: 0
      add :dose, :decimal, null: true
      add :additional_dose, :decimal, null: true
      add :additional_dose_allowed, :boolean, default: false
      add :max_allowed_limit, :decimal, null: true
      add :substance_locked_on_order, :boolean, default: false

      add :dose_unit_id, references(:units, on_delete: :nilify_all), null: true
      add :additional_dose_unit_id, references(:units, on_delete: :nilify_all), null: true
      add :max_allowed_unit_id, references(:units, on_delete: :nilify_all), null: true
      add :template_id, references(:templates, on_delete: :nilify_all), null: false
      add :filling_method_id, references(:filling_methods, on_delete: :nilify_all), null: true
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      # default product
      add :formulary_id, references(:formularies, on_delete: :nilify_all), null: true
      # substance
      add :class_id, references(:classes, on_delete: :nilify_all), null: false
      timestamps()
    end

    execute """
      CREATE OR REPLACE VIEW template_products_view AS
      SELECT tp.id,
      tp.position,
      tp.dose,
      tp.additional_dose,
      tp.additional_dose_allowed,
      tp.max_allowed_limit,
      tp.substance_locked_on_order,
      tp.dose_unit_id,
      tp.additional_dose_unit_id,
      tp.max_allowed_unit_id,
      tp.template_id,
      tp.filling_method_id,
      tp.user_id,
      tp.formulary_id,
      tp.class_id,
      tp.inserted_at,
      tp.updated_at,
      du.unit as dose_unit,
      adu.unit as additional_dose_unit,
      mau.unit as max_allowed_unit,
      t.name as template_name,
      fm.name as filling_method_name,
      u.first_name as user_name,
      f.name as formulary_name,
      c.name as class_name
      FROM template_products tp
      LEFT JOIN units du ON tp.dose_unit_id = du.id
      LEFT JOIN units adu ON tp.additional_dose_unit_id = adu.id
      LEFT JOIN units mau ON tp.max_allowed_unit_id = mau.id
      LEFT JOIN templates t ON tp.template_id = t.id
      LEFT JOIN filling_methods fm ON tp.filling_method_id = fm.id
      LEFT JOIN users u ON tp.user_id = u.id
      LEFT JOIN formularies f ON tp.formulary_id = f.id
      LEFT JOIN classes c ON tp.class_id = c.id
    """

    create index(:template_products, [:template_id, :class_id, :formulary_id],
             unique: true,
             name: :template_products_template_class_formulary_index
           )
  end
end
