defmodule Tpn.Repo.Migrations.UpdateDecimalPrecisionTo4 do
  use Ecto.Migration

  def change do
    # Drop views that depend on the columns we're modifying
    execute "DROP VIEW IF EXISTS formularies_view"
    execute "DROP VIEW IF EXISTS template_products_view"
    execute "DROP VIEW IF EXISTS admissions_view"
    execute "DROP VIEW IF EXISTS templates_view"

    # Update formularies table
    alter table(:formularies) do
      modify :concentration, :decimal, precision: 10, scale: 4
      modify :calories, :decimal, precision: 10, scale: 4
      modify :cost_per_container, :decimal, precision: 10, scale: 4
      modify :container_size, :decimal, precision: 10, scale: 4
    end

    # Update formulary_ingredients table
    alter table(:formulary_ingredients) do
      modify :amount, :decimal, precision: 10, scale: 4
    end

    # Update admissions table
    alter table(:admissions) do
      modify :patient_weight, :decimal, precision: 10, scale: 4
      modify :patient_height, :decimal, precision: 10, scale: 4
    end

    # Update templates table
    alter table(:templates) do
      modify :bag_over_fill_volume, :decimal, precision: 10, scale: 4
      modify :lipid_over_fill_volume, :decimal, precision: 10, scale: 4
      modify :fluids, :decimal, precision: 10, scale: 4
    end

    # Update template_products table
    alter table(:template_products) do
      modify :dose, :decimal, precision: 10, scale: 4
      modify :additional_dose, :decimal, precision: 10, scale: 4
      modify :max_allowed_limit, :decimal, precision: 10, scale: 4
    end

    # Update orders table
    alter table(:orders) do
      modify :enteral_dose, :decimal, precision: 10, scale: 4
      modify :total_price, :decimal, precision: 10, scale: 4
    end

    # Recreate formularies_view
    execute """
      CREATE OR REPLACE VIEW formularies_view AS
      SELECT f.id,
      f.name,
      f.label_friendly_name,
      f.code,
      f.is_enteral,
      f.concentration,
      f.calories,
      f.cost_per_container,
      f.container_size,
      f.print_on_label,
      f.include_in_overfill,
      f.universal_fluid,
      f.class_id,
      f.concentration_unit_id,
      f.calories_unit_id,
      f.uom_unit_id,
      f.solution_type_id,
      f.user_id,
      f.inserted_at,
      f.updated_at,
      c.name as class_name,
      cu.unit as concentration_unit_name,
      calu.unit as calories_unit_name,
      uomu.unit as uom_unit_name,
      st.name as solution_type_name,
      u.first_name as user_name
      FROM formularies f
      LEFT JOIN classes c ON f.class_id = c.id
      LEFT JOIN units cu ON f.concentration_unit_id = cu.id
      LEFT JOIN units calu ON f.calories_unit_id = calu.id
      LEFT JOIN units uomu ON f.uom_unit_id = uomu.id
      LEFT JOIN solution_types st ON f.solution_type_id = st.id
      LEFT JOIN users u ON f.user_id = u.id
    """

    # Recreate template_products_view
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

    # Recreate templates_view
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

    # Recreate admissions_view
    execute """
      CREATE OR REPLACE VIEW admissions_view AS
      SELECT a.id,
             a.admission_no,
             a.discharged,
             a.discharged_at,
             a.age,
             a.notes,
             a.patient_weight,
             a.patient_height,
             a.weight_unit_id,
             a.height_unit_id,
             a.patient_id,
             a.patient_type_id,
             a.local_health_network_id,
             a.facility_id,
             a.campus_id,
             a.ward_id,
             a.room_id,
             a.bed_id,
             a.user_id,
             a.inserted_at,
             a.updated_at,
             p.first_name,
             p.last_name,
             p.identity_no,
             p.tpn_id,
             pt.name AS patient_type,
             lhn.name AS local_health_network,
            f.name AS facility,
            c.name AS campus,
            w.name AS ward,
            r.name AS room,
            b.name AS bed,
            mr.mrn,
            wu.unit AS weight_unit,
            hu.unit AS height_unit,
            u.first_name AS user_name
            FROM admissions a
            LEFT JOIN patients p ON a.patient_id = p.id
            LEFT JOIN patient_types pt ON a.patient_type_id = pt.id
            LEFT JOIN local_health_networks lhn ON a.local_health_network_id = lhn.id
            LEFT JOIN facilities f ON a.facility_id = f.id
            LEFT JOIN campuses c ON a.campus_id = c.id
            LEFT JOIN wards w ON a.ward_id = w.id
            LEFT JOIN rooms r ON a.room_id = r.id
            LEFT JOIN beds b ON a.bed_id = b.id
            LEFT JOIN users u ON a.user_id = u.id
            LEFT JOIN patient_mrns mr ON a.campus_id = mr.campus_id AND a.patient_id = mr.patient_id
            LEFT JOIN units wu ON a.weight_unit_id = wu.id
            LEFT JOIN units hu ON a.height_unit_id = hu.id
    """
  end
end
