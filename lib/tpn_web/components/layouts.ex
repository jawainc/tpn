defmodule TpnWeb.Layouts do
  use TpnWeb, :html

  import TpnWeb.LayoutComponents.Administrator.{DesktopMenu, Header}
  import TpnWeb.LayoutComponents.App.{Menu, TopBar}

  embed_templates "layouts/*"
end
