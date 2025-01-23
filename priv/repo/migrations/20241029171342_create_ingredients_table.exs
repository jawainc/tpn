defmodule Tpn.Repo.Migrations.CreateIngredientsTable do
  use Ecto.Migration

  def change do
    create table(:ingredients) do
      add :name, :string
      add :unit_type_id, references(:unit_types, on_delete: :nilify_all), null: true
      add :print_on_label, :boolean, default: false
      add :user_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:ingredients, [:name])
  end
end
