defmodule Tpn.Repo.Migrations.AddUniqueIndexToFormulariesCode do
  use Ecto.Migration

  def change do
    # Find and update duplicate codes by appending a sequence number
    execute """
    WITH duplicates AS (
      SELECT id, code,
             ROW_NUMBER() OVER (PARTITION BY code ORDER BY id) as rn
      FROM formularies
    )
    UPDATE formularies
    SET code = CONCAT(formularies.code, '_', duplicates.rn)
    FROM duplicates
    WHERE formularies.id = duplicates.id
    AND duplicates.rn > 1
    """

    # Now create the unique index
    create unique_index(:formularies, [:code])
  end
end
