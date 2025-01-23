defmodule TpnWeb.DashBoardHTML do
  use TpnWeb, :html

  import TpnWeb.LayoutComponents.App.{Menu, TopBar}

  embed_templates "dashboard_html/*"
end
