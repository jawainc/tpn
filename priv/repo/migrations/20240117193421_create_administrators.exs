defmodule TpnApi.Repo.Migrations.CreateAdministrators do
  use Ecto.Migration

  def change do
    create table(:administrators) do
      add :name, :string
      add :login_id, :string
      add :hashed_password, :string

      timestamps()
    end

    create unique_index(:administrators, [:login_id])
  end
end
