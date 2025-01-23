defmodule Tpn.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :contact_no, :string, null: true
      add :active, :boolean, default: true
      add :deleted, :boolean, default: false

      add :role_id, references(:roles), null: false
      add :local_health_network_id, references(:local_health_networks), null: true
      add :facility_id, references(:facilities), null: true
      add :campus_id, references(:campuses), null: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
      add :administrator_id, references(:administrators, on_delete: :delete_all), null: true
      add :token, :binary, null: false
      add :context, :string, null: false
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
