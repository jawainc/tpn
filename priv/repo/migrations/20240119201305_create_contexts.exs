defmodule TpnApi.Repo.Migrations.CreateContexts do
  use Ecto.Migration

  def change do
    create table(:contexts) do
      add :name, :string, null: false
      add :table, :string, null: false

      timestamps()
    end

    create unique_index(:contexts, [:name], name: :context_name_index)
  end
end
