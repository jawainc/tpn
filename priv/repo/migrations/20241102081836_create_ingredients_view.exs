defmodule Tpn.Repo.Migrations.CreateIngredientsView do
  use Ecto.Migration

  def change do
    execute """
    CREATE OR REPLACE VIEW ingredients_view AS
    SELECT
      i.id,
      i.name,
      i.unit_type_id,
      i.print_on_label,
      i.user_id,
      i.inserted_at,
      u.first_name AS user_name,
      ut.name AS unit_type
    FROM ingredients i
    LEFT JOIN unit_types ut ON i.unit_type_id = ut.id
    LEFT JOIN users u ON i.user_id = u.id
    """
  end
end
