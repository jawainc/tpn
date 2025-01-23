defmodule TpnWeb.SettingsHTML do
  use TpnWeb, :html
  import TpnWeb.Settings.Components.SettingComponents

  embed_templates "settings_html/*"

  def get_selected_record(key, records) do
    record = Enum.find(records, fn record -> record.key == key end)

    case record do
      nil -> ""
      _ -> record.value
    end
  end
end
