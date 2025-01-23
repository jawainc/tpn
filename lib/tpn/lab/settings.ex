defmodule Tpn.Settings do
  import Ecto.Query, warn: false
  alias Tpn.Repo
  alias Tpn.Setting

  def get_settings() do
    Repo.all(Setting)
  end

  def insert_setting(maps) do
    Repo.insert_all(
      Setting,
      maps,
      on_conflict: {:replace, [:value, :user_id, :updated_at]},
      conflict_target: [:key]
    )
  end
end
