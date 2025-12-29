defmodule Tpn.Repo.Migrations.AddUniqueIndexToUnitsUnit do
  use Ecto.Migration

  def change do
    # Find and update duplicate units by appending a sequence number
    execute """
    WITH duplicates AS (
      SELECT id, unit,
             ROW_NUMBER() OVER (PARTITION BY unit ORDER BY id) as rn
      FROM units
    )
    UPDATE units
    SET unit = CONCAT(units.unit, '_', duplicates.rn)
    FROM duplicates
    WHERE units.id = duplicates.id
    AND duplicates.rn > 1
    """

    # Now create the unique index
    create unique_index(:units, [:unit])
  end
end
